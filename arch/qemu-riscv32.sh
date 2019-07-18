#
# MIT License
#
# Copyright(c) 2011-2019 The Maintainers of Nanvix
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

#
# Sets up development tools.
#
function setup_toolchain
{
	# Required variables.
	local CURDIR=`pwd`
	local WORKDIR=$CURDIR/toolchain/riscv32
	local PREFIX=$WORKDIR
	local TARGET=riscv32-elf
	local COMMIT=1fed470a3a0b59405887c8e0cc2e253f1f7b6643
	
	# Retrieve the number of processor cores
	local NCORES=`grep -c ^processor /proc/cpuinfo`
	
	mkdir -p $WORKDIR
	cd $WORKDIR
	
	# Get toolchain.
	wget "https://github.com/nanvix/toolchain/archive/$COMMIT.zip"
	unzip $COMMIT.zip
	mv toolchain-$COMMIT/* .
	
	# Cleanup.
	rm -rf toolchain-$COMMIT
	rm -rf $COMMIT.zip
	
	# Build binutils.
	cd binutils*/
	./configure --target=$TARGET --prefix=$PREFIX --disable-nls
	make -j $NCORES all
	make install
	
	# Cleanup.
	cd $WORKDIR
	rm -rf binutils*
	
	# Build GCC.
	cd gcc*/
	./contrib/download_prerequisites
	mkdir build
	cd build
	../configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers --disable-multilib
	make -j $NCORES all-gcc
	make -j $NCORES all-target-libgcc
	make install-gcc
	make install-target-libgcc
	
	# Cleanup.
	cd $WORKDIR
	rm -rf gcc*
	
	# Build GDB.
	cd $WORKDIR
	cd gdb*/
	./configure --target=$TARGET --prefix=$PREFIX --with-auto-load-safe-path=/ --with-guile=no
	make -j $NCORES
	make install
	
	# Cleanup.
	cd $WORKDIR
	rm -rf gdb*
	
	# Back to the current folder
	cd $CURDIR
}

#
# Builds system image.
#
function build
{
	# Nothing to do.
	echo ""
}

#
# Runs a binary in the platform (simulator).
#
function run
{
	local image=$1
	local bindir=$2
	local binary=$3
	local target=$4
	local variant=$5
	local mode=$6
	local timeout=$7

	# Target configuration.
	local MEMSIZE=128M # Memory Size
	local NCORES=5     # Number of Cores
		
	if [ $mode == "--debug" ];
	then
		qemu-system-riscv32 -s -S   \
			-machine virt           \
			-kernel $bindir/$binary \
			-serial stdio           \
			-display none           \
			-m $MEMSIZE             \
			-mem-prealloc           \
			-smp $NCORES
	else
		if [ -n $timeout ];
		then
			timeout --foreground  $timeout \
			qemu-system-riscv32 -s         \
				-machine virt              \
				-kernel $bindir/$binary    \
				-serial stdio              \
				-display none              \
				-m $MEMSIZE                \
				-mem-prealloc              \
				-smp $NCORES               \
			|& tee $OUTFILE
			line=$(cat $OUTFILE | tail -1)
			if [ "$line" = "[hal] powering off..." ];
			then
				echo "Succeed !"
			else
				echo "Failed !"
				return -1
			fi
		else
			qemu-system-riscv32 -s      \
				-machine virt           \
				-kernel $bindir/$binary \
				-serial stdio           \
				-display none           \
				-m $MEMSIZE             \
				-mem-prealloc           \
				-smp $NCORES
		fi
	fi
}
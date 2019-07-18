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
	local WORKDIR=$CURDIR/toolchain/or1k
	local PREFIX=$WORKDIR
	local TARGET=or1k-elf
	local COMMIT=5b661a015490505201e21284914a169bcdad877e
	
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
	
	# Build binutils and GDB.
	cd binutils*/
	./configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-sim --with-auto-load-safe-path=/ --enable-tui --with-guile=no
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
	../configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers
	make -j $NCORES all-gcc
	make -j $NCORES all-target-libgcc
	make install-gcc
	make install-target-libgcc
	
	# Cleanup.
	cd $WORKDIR
	rm -rf gcc*
	
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
	local NCORES=2     # Number of Cores
		
	if [ $mode == "--debug" ];
	then
		qemu-system-or1k -s -S      \
			-kernel $bindir/$binary \
			-serial stdio           \
			-display none           \
			-m $MEMSIZE             \
			-mem-prealloc           \
			-smp $NCORES
	else
		if [ -n $timeout ];
		then
			timeout --foreground $timeout \
			qemu-system-or1k -s           \
				-kernel $bindir/$binary   \
				-serial stdio             \
				-display none             \
				-m $MEMSIZE               \
				-mem-prealloc             \
				-smp $NCORES              \
			|& tee $OUTFILE
			line=$(cat $OUTFILE | tail -2 | head -1)
			if [ "$line" = "[hal] powering off..." ];
			then
				echo "Succeed !"
			else
				echo "Failed !"
				return -1
			fi
		else
			qemu-system-or1k -s         \
				-kernel $bindir/$binary \
				-serial stdio           \
				-display none           \
				-m $MEMSIZE             \
				-mem-prealloc           \
				-smp $NCORES
		fi
	fi
}

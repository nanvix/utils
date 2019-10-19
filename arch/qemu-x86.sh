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
# GDB Port.
#
GDB_PORT=1234

#
# Sets up development tools.
#
function setup_toolchain
{
	local CURDIR=`pwd`
	local WORKDIR=$SCRIPT_DIR/toolchain/i486
	local PREFIX=$WORKDIR
	local TARGET=i486-elf
	local COMMIT=8dc3bfa2be9b7165188cfe0718ad0571a11cc649

	# Retrieve the number of processor cores
	local NCORES=`grep -c ^processor /proc/cpuinfo`

	mkdir -p $WORKDIR
	cd $WORKDIR

	# Get toolchain.
	wget "https://github.com/nanvix/toolchain/archive/$COMMIT.zip"
	unzip $COMMIT.zip
	mv toolchain-$COMMIT/* .

	# Cleanup
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
	cd $WORKDIR
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
	local image=$1
	local bindir=$2
	local imgsrc=$3

	# Create multi-binary image.
	truncate -s 0 $image
	for binary in `cat $imgsrc`;
	do
		echo $binary >> $image
	done
}

#
# Very simple way of testing if the network interfaces exists.
# Testing if network interfaces are UP should be added
#
function check_network
{
	if [ -e /sys/class/net/$TAP_NAME ];
	then
		echo "Network TAP interface is setup"
	else
		echo "You should setup a TAP interface:"
		echo "    sudo bash ./utils/nanvix-setup-network.sh on"
		exit 1
	fi
}

#
# Spawns binaries.
#
# $1 Binary directory.
# $2 Multibinary image.
# $3 Spawn mode.
# $4 Timeout.
#
function spawn_binaries
{
	local bindir=$1
	local image=$2
	local mode=$3
	local timeout=$4
	local cmd=""

	# Target configuration.
	local MEMSIZE=128M # Memory Size
	local IMAGE_ID=1   # Image ID

	check_network

	let i=0

	qemu_cmd="qemu-system-i386
			-serial stdio
			-display curses
			-m $MEMSIZE
			-mem-prealloc"

	for binary in `cat $image`;
	do

		local tapname="nanvix-tap"$IMAGE_ID
		local mac="52:55:00:d1:55:0"$IMAGE_ID

		cmd="$qemu_cmd -gdb tcp::$GDB_PORT"
		cmd="$cmd -kernel $bindir/$binary"
		cmd="$cmd -netdev tap,id=t0,ifname=$tapname,script=no,downscript=no"
		cmd="$cmd -device rtl8139,netdev=t0,id=nic0,mac=$mac"

		# Spawn cluster.
		if [ $mode == "--debug" ];
		then
			cmd="$cmd -S"
			$cmd
		else
			$cmd
		fi

		let i++
		let IMAGE_ID++
		let GDB_PORT++

		# No multicluster spawn.
		break

	done
}

#
# Runs a binary in the platform (simulator).
#
function run
{
	
	local image=$1    # Multibinary image.
	local bindir=$2   # Binary directory.
	local target=$3   # Target (unused).
	local variant=$4  # Cluster variant (unused)
	local mode=$5     # Spawn mode (run or debug).
	local timeout=$6  # Timeout for test mode.
	local ret=0       # Return value.

	spawn_binaries $bindir $image $mode

	return $ret
}

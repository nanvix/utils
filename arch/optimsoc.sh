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

export OBJCOPY="or1k-elf-objcopy"
export BIN2VMEM="/opt/optimsoc/bin2vmem"
export BLUEDRAGON="/opt/bluedragon/bluedragon"

#
# Sets up development tools.
#
function setup_toolchain
{
	# Nothing to do.
	echo ""
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
		filename=`echo $binary | cut -d "." -f 1`
		$OBJCOPY -O binary $bindir/$binary $bindir/$filename.bin
		$BIN2VMEM $bindir/$filename.bin > $bindir/$filename.vmem
		echo "$filename.vmem" >> $image
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

	binary=`head -n 1 $image`

	if [ ! -z $timeout ];
	then
		timeout --foreground $timeout \
		$BLUEDRAGON --meminit=$bindir/$binary
	else
		$BLUEDRAGON --meminit=$bindir/$binary
	fi
}

#
# Runs a binary in the platform (hardware).
#
function run_hw
{
	local binary=$3
	local mode=$6
	local timeout=$7

	echo "timeout=$timeout"

	if [ ! -z $timeout ];
	then
		if [ $mode == "--debug" ];
		then

			timeout --foreground $timeout           \
			osd-target-run                          \
				-e $binary                            \
				-b uart                               \
				-o device=/dev/ttyUSB1,speed=12000000 \
				--systrace                            \
				--coretrace                           \
				-vvv
		else
			osd-target-run                          \
				-e $binary                            \
				-b uart                               \
				-o device=/dev/ttyUSB1,speed=12000000 \
				--systrace                            \
				-vvv
		fi
	else
		if [ $mode == "--debug" ];
		then
			osd-target-run                          \
				-e $binary                            \
				-b uart                               \
				-o device=/dev/ttyUSB1,speed=12000000 \
				--systrace                            \
				--coretrace                           \
				-vvv
		else
			osd-target-run                          \
				-e $binary                            \
				-b uart                               \
				-o device=/dev/ttyUSB1,speed=12000000 \
				--systrace                            \
				-vvv
		fi
	fi
}

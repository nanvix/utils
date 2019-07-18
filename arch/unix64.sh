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
	# Nothing to do.
	echo ""
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
	local NCORES=4     # Number of Cores
		
	if [ $mode == "--debug" ];
	then
		gdb $bindir/$binary
	else
		if [ -n $timeout ];
		then
			timeout --foreground  $timeout \
				$bindir/$binary            \
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
			$bindir/$binary
		fi
	fi
}

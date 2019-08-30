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
	local cmd=""

	# Target configuration.
	local MEMSIZE=128M # Memory Size
	local NCLUSTERS=18 # Number of Clusters

	case $variant in
		"all")
			cmd="$bindir/$binary --nclusters $NCLUSTERS"
			;;
		"iocluster")
			cmd="$bindir/$binary --nclusters 1"
			;;
		"ccluster")
			echo "error: cluster variant not supported"
			exit 0
			;;
	esac

	if [ $mode == "--debug" ];
	then
		gdbserver localhost:1234 $cmd
	else
		if [ ! -z $timeout ];
		then
			timeout --foreground $timeout     \
				$bindir/$binary --nclusters 2 \
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
			$cmd
		fi
	fi
}

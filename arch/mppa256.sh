#
# MIT License
#
# Copyright(c) 2018 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
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

export K1_TOOLCHAIN_DIR="/usr/local/k1tools"

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
	local image=`basename $1`
	local imgpath=$1
	local bindir=$2
	local imgsrc=$3
	local ios=""
	local clusters=""

	# Create multi-binary image.
	truncate -s 0 $image
	for binary in `cat $imgsrc`;
	do
		clusterid=`echo $binary | cut -d ":" -f 1`
		bin=`echo $binary | cut -d ":" -f 2`
		imgdir=`echo $image | cut -d "." -f 1`

		# Create binary folder for current image.
		mkdir -p $bindir/$imgdir

		# Rename binary.
		cp $bindir/$bin $bindir/$imgdir/$clusterid.mppa256

		if [[ "$bin" = *"k1bdp" ]];
		then
			clusters="bin/$imgdir/$clusterid.mppa256,$clusters"
		else
			ios="bin/$imgdir/$clusterid.mppa256,$ios"
		fi
	done

	# Get boot cluster.
	boot=`echo $ios | cut -d "," -f 1`
	ios=`echo $ios | cut -d "," -f 2-`

	# Remove commas.
	ios=${ios%?}
	clusters=${clusters%?}

	echo "BOOT = $boot"
	echo "IOS = $ios"
	echo "CLUSTERS = $clusters"

	cmd="$K1_TOOLCHAIN_DIR/bin/k1-create-multibinary"
	cmd="$cmd --boot $boot"
	if [[ ! -z $ios ]];
	then
		cmd="$cmd --ios=$ios"
	fi

	if [[ ! -z $clusters ]];
	then
		cmd="$cmd --clusters=$clusters"
	fi
	cmd="$cmd -T $imgpath -f"

	$cmd
}

function parse
{
	local outfile=$1
	local failed='failed|FAILED|Failed'
	local success='false'

	while read -r line;
	do
		if [[ $line =~ $failed ]]; then
			echo "Failed !"
			return 255
		fi

		if [[ $line = *"IODDR0@0.0: RM 0: [hal] powering off"* ]]; then
			success='true'
		fi
	done < "$outfile"

	if [[ $success == true ]];
	then
		echo "Succeed !"
	else
		echo "Failed !"
		return 255
	fi

	return 0
}

#
# Runs a binary in the platform.
#
function run
{
	local image=$1    # Multibinary image.
	local bindir=$2   # Binary directory.
	local target=$3   # Target (unused).
	local variant=$4  # Cluster variant (unused)
	local mode=$5     # Spawn mode (run or debug).
	local timeout=$6  # Timeout for test mode.

	# Concatenates bindir with current imgdir folder
	imgdir="$bindir/`echo $image | cut -d "." -f 1`"

	local execfile="\
		--exec-file=IODDR0:$imgdir/iocluster0.mppa256    \
		--exec-file=IODDR1:$imgdir/iocluster1.mppa256    \
		--exec-file=Cluster0:$imgdir/ccluster0.mppa256   \
		--exec-file=Cluster1:$imgdir/ccluster1.mppa256   \
		--exec-file=Cluster2:$imgdir/ccluster2.mppa256   \
		--exec-file=Cluster3:$imgdir/ccluster3.mppa256   \
		--exec-file=Cluster4:$imgdir/ccluster4.mppa256   \
		--exec-file=Cluster5:$imgdir/ccluster5.mppa256   \
		--exec-file=Cluster6:$imgdir/ccluster6.mppa256   \
		--exec-file=Cluster7:$imgdir/ccluster7.mppa256   \
		--exec-file=Cluster8:$imgdir/ccluster8.mppa256   \
		--exec-file=Cluster9:$imgdir/ccluster9.mppa256   \
		--exec-file=Cluster10:$imgdir/ccluster10.mppa256 \
		--exec-file=Cluster11:$imgdir/ccluster11.mppa256 \
		--exec-file=Cluster12:$imgdir/ccluster12.mppa256 \
		--exec-file=Cluster13:$imgdir/ccluster13.mppa256 \
		--exec-file=Cluster14:$imgdir/ccluster14.mppa256 \
		--exec-file=Cluster15:$imgdir/ccluster15.mppa256"

	if [ $mode == "--debug" ];
	then
		$K1_TOOLCHAIN_DIR/bin/k1-jtag-runner \
			--gdb                            \
			--multibinary=$image             \
			$execfile
	else
		if [ ! -z $timeout ];
		then
			timeout --foreground $timeout        \
			$K1_TOOLCHAIN_DIR/bin/k1-jtag-runner \
				--multibinary=$image             \
				$execfile                        \
			|& tee $OUTFILE

			parse $OUTFILE
		else
			$K1_TOOLCHAIN_DIR/bin/k1-jtag-runner         \
				--multibinary=$image                     \
				$execfile                                \
			|& tee >(grep IODDR0@    > nanvix-cluster-0)  \
			|& tee >(grep IODDR1@    > nanvix-cluster-1)  \
			|& tee >(grep Cluster0@  > nanvix-cluster-2)  \
			|& tee >(grep Cluster1@  > nanvix-cluster-3)  \
			|& tee >(grep Cluster2@  > nanvix-cluster-4)  \
			|& tee >(grep Cluster3@  > nanvix-cluster-5)  \
			|& tee >(grep Cluster4@  > nanvix-cluster-6)  \
			|& tee >(grep Cluster5@  > nanvix-cluster-7)  \
			|& tee >(grep Cluster6@  > nanvix-cluster-8)  \
			|& tee >(grep Cluster7@  > nanvix-cluster-9)  \
			|& tee >(grep Cluster8@  > nanvix-cluster-10) \
			|& tee >(grep Cluster9@  > nanvix-cluster-11) \
			|& tee >(grep Cluster10@ > nanvix-cluster-12) \
			|& tee >(grep Cluster11@ > nanvix-cluster-13) \
			|& tee >(grep Cluster12@ > nanvix-cluster-14) \
			|& tee >(grep Cluster13@ > nanvix-cluster-15) \
			|& tee >(grep Cluster14@ > nanvix-cluster-16) \
			|& tee >(grep Cluster15@ > nanvix-cluster-17)
		fi
	fi
}

#
# Runs a binary in the platform (simulator).
#
function run_sim
{
	local bin=$1
	local args=$2

	$K1_TOOLCHAIN_DIR/bin/k1-cluster \
		--mboard=$BOARD           \
		--march=$ARCH             \
		--bootcluster=node0       \
		-- $bin $args
}

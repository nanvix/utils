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

function parse_outputs
{
	local outfile=$1
	local failed='failed|FAILED|Failed'
	local success='false'

	while read -r line;
	do
		if [[ $line =~ $failed ]];
		then
			echo "Failed !"
			return 255
		fi

		if [[ $line = *"IODDR0@0.0: RM 0: [hal] powering off"* ]];
		then
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

	# Initial exec file
	local execfile=""

	# Populate exec file with current available binaries
	for cluster in `ls $imgdir | grep -o "[c-o]cluster[0-9]*[0-9]\."`;
	do
		type=`echo ${cluster: 0:1}`
		number=`echo $cluster | grep -Eo "[0-9]{1,2}"`

		if [ $type == "c" ]; then
			execfile="$execfile \
				--exec-file=Cluster$number:$imgdir/ccluster$number.mppa256"
		else
			execfile="$execfile \
				--exec-file=IODDR$number:$imgdir/iocluster$number.mppa256"
		fi
	done

	if [ $NANVIX_PROFILE == "true" ];
	then
		$TOOLCHAIN_DIR/bin/k1-power -s                                 \
			--refresh-rate=0.1                                         \
			--profile=mppa0_pwr,mppa0_temp,plx_temp,ddr0_pwr,ddr1_pwr  \
			--traces_keep --output=$PWD                                \
		> /dev/null &
		K1_POWER_PID=$!
	fi

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

			parse_outputs $OUTFILE
		else
			$K1_TOOLCHAIN_DIR/bin/k1-jtag-runner          \
				--multibinary=$image                      \
				$execfile                                 \
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

	if [ $NANVIX_PROFILE == "true" ];
	then
		kill -SIGKILL $K1_POWER_PID
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

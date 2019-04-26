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

# Script Arguments
IMAGE=$1    # Image
BINARY=$2   # Binary
TARGET=$3   # Target
VARIANT=$4  # Target Variant
MODE=$5     # Run Mode
ARGS=$6     # Image Arguments

# Variables
SCRIPT_NAME=$0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

#==============================================================================
# usage()
#==============================================================================

#
# Prints script usage and exits.
#
function usage
{
	echo "$SCRIPT_NAME <image> <binary> <target> <target variant> [mode]"
	exit 1
}

#==============================================================================
# check_args()
#==============================================================================

#
# Check script arguments.
#
function check_args
{
	# Missing image?
	if [ -z $IMAGE ];
	then
		echo "$SCRIPT_NAME: missing image"
		usage
	fi

	# Missing binary?
	if [ -z $IMAGE ];
	then
		echo "$SCRIPT_NAME: missing image"
		usage
	fi

	# Missing target?
	if [ -z $TARGET ];
	then
		echo "$SCRIPT_NAME: missing target"
		usage
	fi

	case $VARIANT in
		"--all" | "--iocluster" | "--ccluster")
			;;
		*)
			echo "$SCRIPT_NAME: bad target variant [--all | --iocluster | --ccluster]"
			exit 1
			;;
	esac
}

#==============================================================================

# No debug mode.
if [ -z $MODE ];
then
	MODE="--no-debug"
fi

# Verbose mode.
if [[ ! -z $VERBOSE ]];
then
	echo "==============================================================================="
	echo "SCRIPT_DIR  = $SCRIPT_DIR"
	echo "SCRIPT_NAME = $SCRIPT_NAME"
	echo "IMAGE       = $IMAGE"
	echo "BINARY      = $BINARY"
	echo "TARGET      = $TARGET"
	echo "VARIANT     = $VARIANT"
	echo "MODE        = $MODE"
	echo "ARGS        = $ARGS"
	echo "==============================================================================="
fi

# Source target configuration
case "$TARGET" in
	"qemu-x86"      | \
	"qemu-openrisc" | \
	"qemu-riscv32"  | \
	"mppa256")
		source $SCRIPT_DIR/arch/$TARGET.sh
		;;
	*)
        echo "error: unsupported target"
		usage
		;;
esac

run $IMAGE $BINARY $TARGET $VARIANT $MODE $ARGS

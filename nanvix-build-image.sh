#
# MIT License
#
# Copyright (c) 2011-2018 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.  THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Arguments
IMAGE=$1   # Image File Name
BINDIR=$2  # Binary Directory
BINARY=$3  # Binary File Name

# Global Variables
export SCRIPT_NAME=$0
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

#==============================================================================
# usage()
#==============================================================================

#
# Prints script usage and exits.
#
function usage
{
	echo "$SCRIPT_NAME <bindir> <binary> <image>"
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
	# Missing target.
	if [ -z $TARGET ]; then
		echo "$SCRIPT_NAME: missing target"
		exit 1
	fi

	# Missing binary directory.
	if [ -z $BINDIR ] ;
	then
		echo "$SCRIPT_NAME: missing binary directory"
		exit 1
	fi

	# Missing binary file name.
	if [ -z $BINARY ] ;
	then
		echo "$SCRIPT_NAME: missing binary file name"
		exit 1
	fi

	# Missing image file name.
	if [ -z $IMAGE ];
	then
		echo "$SCRIPT_NAME: missing image file name"
		usage
	fi
}

#==============================================================================

# Verbose mode.
if [[ ! -z $VERBOSE ]];
then
	echo "==============================================================================="
	echo "SCRIPT_DIR  = $SCRIPT_DIR"
	echo "SCRIPT_NAME = $SCRIPT_NAME"
	echo "TARGET      = $TARGET"
	echo "VARIANT     = $VARIANT"
	echo "IMAGE       = $IMAGE"
	echo "BINARY      = $BINDIR/$BINARY"
	echo "==============================================================================="
fi

# Source Target Configuration
case "$TARGET" in
	"qemu-x86"      | \
	"qemu-openrisc" | \
	"qemu-riscv32"  | \
	"unix64"        | \
	"mppa256"       | \
	"optimsoc")
		source $SCRIPT_DIR/arch/$TARGET.sh
		;;
	*)
        echo "error: unsupported target"
		usage
		;;
esac

# Build multi-binaries.
build $IMAGE $BINDIR $BINARY

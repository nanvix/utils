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
#

#
# NOTES:
#   - This script setup (and reset) a Network TAP interface and a bridge for
#  QEMU networking to work properly on qemu-x86.
#   - You should run this script with superuser privileges.

# Script Arguments
COMMAND=$1    # Command, either on or off

# Global Variables
export SCRIPT_NAME=$0

# Options
# be careful changing those values, they are also hard coded in the qemu-x86.sh script
# but I don't know the proper way to make them dependant.
TAP_INTERFACE_NAME=nanvix-tap
BRIDGE_INTERFACE_NAME=nanvix-bridge
TAP_IP_ADRESS=192.168.66.66/24
#==============================================================================
# usage()
#==============================================================================

#
# Prints script usage and exits.
#
function usage
{
	echo "$SCRIPT_NAME <command>
        command: [on | off]"
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
	if [ -z $COMMAND ];
	then
		echo "$SCRIPT_NAME: missing command"
		usage
	fi

	case $COMMAND in
		"on" | "off")
			;;
		*)
			echo "$SCRIPT_NAME: bad command [on | off]"
			exit 1
			;;
	esac
}

#==============================================================================

#
# Setup a TAP interface and a bridge, link them together and 
# give the TAP interface an IP adress
#
function on
{
    sudo ip link add $BRIDGE_INTERFACE_NAME type bridge
    sudo ip tuntap add dev $TAP_INTERFACE_NAME mode tap
    sudo ip link set $TAP_INTERFACE_NAME master $BRIDGE_INTERFACE_NAME
    sudo ip link set dev $BRIDGE_INTERFACE_NAME up
    sudo ip link set $TAP_INTERFACE_NAME up
    sudo ip addr add dev $TAP_INTERFACE_NAME $TAP_IP_ADRESS

    echo "Network interfaces successfully setup"
    echo "Remember that you can remove the interfaces :
        sudo bash $SCRIPT_NAME off"
}

#
# Remove the previously created interfaces
#
function off
{
    sudo ip link delete $TAP_INTERFACE_NAME
    sudo ip link delete $BRIDGE_INTERFACE_NAME

    echo "Network interfaces successfully reset"
}

check_args

case $COMMAND in
    "on")
        on
        ;;
    "off")
        off
        ;;
    *) # Should never happen
        echo "$SCRIPT_NAME: bad command [on | off]"
        exit 1
        ;;
esac


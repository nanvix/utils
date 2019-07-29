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
#   - You should run this script with superuser privileges.
#

# Script Arguments
COMMAND=$1  # Command, either on or off
IS_ROOT=$2  # Running as root?

#
# Get name of target user.
#
USERNAME=$SUDO_USER
if [ ! -z $IS_ROOT ] && [ $IS_ROOT == "--root" ];
then
	USERNAME="root"
fi



# Global Variables
export SCRIPT_NAME=$0

#
# Network Options
#
# Careful when changing these valies. They are
# hard coded in the in target-specific scripts.
#
TAP_NAME=nanvix-tap
IP_ADDR=192.168.66.66
IP_NETMASK_CIDR=24
IP_NETMASK=255.255.255.0

#==============================================================================
# usage()
#==============================================================================

#
# Prints script usage and exits.
#
function usage
{
	echo "$SCRIPT_NAME <on | off> [--root]"
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
			echo "$SCRIPT_NAME: bad command"
			usage
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
	# We don't have tunctl.
	if  [ $(which tunctl > /dev/null) ];
	then
		echo "tunctl utility is missing"
		exit 1
	fi

	# We don't have ip.
	if [ $(which ip > /dev/null) ];
	then
		echo "ip utility is missing"
		exit 1
	fi

	# We don't have ip.
	if [ $(which ifconfig > /dev/null) ];
	then
		echo "ifconfig utility is missing"
		exit 1
	fi

	# Create device node.
	if [ ! -e /dev/net/$TAP_NAME ];
	then
		mknod /dev/net/$TAP_NAME c 10 200
		chown $USERNAME:$USERNAME /dev/net/$TAP_NAME
	fi

	# Create tap interface.
	if [ ! -e /sys/class/net/$TAP_NAME ];
	then
		tunctl -t $TAP_NAME -u $USERNAME > /dev/null
	fi

	# Setup tap interface.
	ip addr add $IP_ADDR/$IP_NETMASK_CIDR dev $TAP_NAME
	ifconfig $TAP_NAME $IP_ADDR netmask $IP_NETMASK up
	ifconfig $TAP_NAME hw ether 52:55:00:d1:55:01
	ip link set dev $TAP_NAME up

	echo "Network interface successfully setup!"
	echo "Remember that you can remove the interfaces:"
	echo "    bash $SCRIPT_NAME off"
}

#
# Remove the previously created interfaces
#
function off
{
	ip addr delete $IP_ADDR/$IP_NETMASK_CIDR dev $TAP_NAME
	ifconfig $TAP_NAME down
	ip link delete dev $TAP_NAME
	tunctl -d $TAP_NAME > /dev/null
	unlink /dev/net/$TAP_NAME

    echo "Network interface successfully removed!"
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


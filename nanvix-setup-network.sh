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
TAP_NB=$2  # Command, either on or off

# Global Variables
export SCRIPT_NAME=$0

#
# Network Options
#
# Careful when changing these valies. They are
# hard coded in the in target-specific scripts.
#
TAP_NAME_PREFIX=nanvix-tap
IP_ADDR_PREFIX=192.169.66.
MAC_ADDR_PREFIX=52:55:00:d1:55:
IP_BRIDGE=200
IP_NETMASK_CIDR=24
IP_NETMASK=255.255.255.0

BRIDGE_NAME=nanvix-bridge

#==============================================================================
# usage()
#==============================================================================

#
# Prints script usage and exits.
#
function usage
{
	echo "$SCRIPT_NAME <on | off> <number of instances [1 .. 99]>"
	exit 1
}

#==============================================================================
# check_args()
#==============================================================================
USERNAME=$(logname 2>/dev/null || echo $SUDO_USER)

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

	# If there is a command
	if [ $COMMAND == "on" ] || [ $COMMAND == "off" ];
	then
		# If there is a number of interfaces
		if [ ! -z $TAP_NB ];
		then
			# Check if valid
			if [[ ! $TAP_NB =~ ^[0-9]+$ ]]
			then
				echo "$SCRIPT_NAME: bad command"
				usage
			fi

			# Valid range
			if [ "$TAP_NB" -ge 100 -o "$TAP_NB" -le 0 ]
			then
				echo "$SCRIPT_NAME: bad command"
				usage
			fi
		else
			TAP_NB=1
		fi
	else
		echo "$SCRIPT_NAME: bad command"
		usage
	fi
}

#==============================================================================

function on_multiple
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

	ip link add name $BRIDGE_NAME type bridge
	IP_ADDR=$IP_ADDR_PREFIX$IP_BRIDGE
	ip addr add $IP_ADDR/$IP_NETMASK_CIDR dev $BRIDGE_NAME
	ip link set dev $BRIDGE_NAME up

	for (( i=1; i<=$TAP_NB; i++ ))
	do
		TAP_NAME=$TAP_NAME_PREFIX$i
		IP_ADDR=$IP_ADDR_PREFIX$i
		MAC_ADDR=$MAC_ADDR_PREFIX$i
		# Create device node.
		if [ ! -e /dev/net/$TAP_NAME ];
		then
			mknod /dev/net/$TAP_NAME c 10 200
			chown $USERNAME:$(id -gn $USERNAME) /dev/net/$TAP_NAME
		fi

		# Create tap interface.
		if [ ! -e /sys/class/net/$TAP_NAME ];
		then
			tunctl -t $TAP_NAME -u $USERNAME > /dev/null
		fi

		# Setup tap interface.
		ip addr add $IP_ADDR/$IP_NETMASK_CIDR dev $TAP_NAME
		ifconfig $TAP_NAME $IP_ADDR netmask $IP_NETMASK up
		ifconfig $TAP_NAME hw ether $MAC_ADDR
		ip link set dev $TAP_NAME up

		# Adding interface to the bridge
		ip link set dev $TAP_NAME master $BRIDGE_NAME
	done

	echo "Network interface successfully setup!"
	echo "Remember that you can remove the interfaces:"
	echo "    bash $SCRIPT_NAME off $TAP_NB"
}

function off_multiple
{
	for (( i=1; i<=$TAP_NB; i++ ))
	do
		TAP_NAME=$TAP_NAME_PREFIX$i
		IP_ADDR=$IP_ADDR_PREFIX$i
		MAC_ADDR=$MAC_ADDR_PREFIX$i

		ip addr delete $IP_ADDR/$IP_NETMASK_CIDR dev $TAP_NAME
		ifconfig $TAP_NAME down
		ip link delete dev $TAP_NAME
		tunctl -d $TAP_NAME > /dev/null
		unlink /dev/net/$TAP_NAME
	done

	ip addr delete $IP_ADDR_PREFIX$IP_BRIDGE/$IP_NETMASK_CIDR dev $BRIDGE_NAME
	ifconfig $BRIDGE_NAME down
	ip link delete dev $BRIDGE_NAME

    echo "Network interface successfully removed!"
}


check_args

case $COMMAND in
    "on")
        on_multiple
        ;;
    "off")
        off_multiple
        ;;
    *) # Should never happen
        echo "$SCRIPT_NAME: bad command [on | off]"
        exit 1
        ;;
esac

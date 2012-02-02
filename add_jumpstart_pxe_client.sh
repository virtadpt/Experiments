#!/bin/sh

# add_jumpstart_pxe_client.sh - Automates the process of adding an x86 system
#	to a Jumpstart server using PXE.

# by: The Doctor <drwho at virtadpt dot net> 
#	0x807B17C1 / 7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF2B 807B 17C1

# Variables
SERVER_IP="192.168.68.1"
JUMPSTART="$SERVER_IP:/jumpstart"
SYSID="$JUMPSTART/opt/SUNWjass"
OS_IMAGE="$SYSID/OS/Solaris_10"
AIC="$OS_IMAGE/Tools/add_install_client"
SYSTYPE="i86pc"
MAC=""
HOSTNAME=""
TEMP=""
ARGCOUNT=0

# Core code.
# Scan the command line args for the MAC and hostname of the client.  ABEND if
# there isn't one.
if [ "$#" -lt 2 ]; then
	echo "ERROR: Missing command line arguments.  $0 --help for online documentation."
	exit 1
	fi

for arg in $*; do
	ARGCOUNT=$ARGCOUNT+1
	case "${arg}" in
		--help|-h|-?)
			echo "USAGE: $0 --mac|-m aa:bb:cc:dd:ee:ff --hostname|-h hostname"
			exit 1
			;;
		--mac|-m)
# Move argument_vector[current + 1] into $MAC
			MAC="$((ARGCOUNT + 1))"
			;;
		--hostname|-h)
# Move argument_vector[current + 1] into $HOSTNAME
			HOSTNAME="$((ARGCOUNT + 1}"
			;;
	esac

done

# Convert the MAC of the client into the format the DHCP table expects.
TEMP=`echo $MAC | tr [:lower:] [:upper:] | sed 's/://g'`
MAC="01$TEMP"

# Add an entry to the DHCP client table.
dhtadm -A -m $HOSTNAME -d ":BootSrvA=$SERVER_IP:BootFile=$MAC:"

# Add the client to the TFTP server.
$AIC -d -e $MAC -c $JUMPSTART -p $SYSID -s $OS_IMAGE $SYSTYPE

echo "Client $MAC added to DHCP and TFTP servers for net.booting."

# Clean up.
exit 0

# End of core code.

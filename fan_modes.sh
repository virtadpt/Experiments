#!/bin/sh

# fan_modes.sh - SYSV initscript-style utility that controls the system fans on
#	Dell laptops.  Called by the laptop-mode utility.  Whenever battery mode
#	is turned off, the fans go to full power.  Whenever battery mode is
#	turned on (i.e., AC power is disconnected and the laptop is running on
#	the power cell) the fans go to low power.

# By: The Doctor <drwho at virtadpt dot net>
#	0x807B17C1 / 7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF2B 807B 17C1

# TODO:	-

# Variables

# Core code.

# Here's where the heavy lifting happens - this parses the arguments passed to
# script and triggers what has to be triggered.
case "$1" in
	'start')
		i8kfan 1 1
		;;
	'stop')
		i8kfan 2 2
		;;
	*)
		echo "USAGE: $0 {start|stop}"
		exit 0
	esac

# End of script.

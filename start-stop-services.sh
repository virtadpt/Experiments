#!/bin/sh

# This script gets called by laptop-tools when the machine's mode switches
# in response to whether or not it's running on battery power.  I use it to
# start or stop certain services that hit the disk a lot to minimize power
# usage.  Goes in /usr/local/sbin, symlink into /etc/laptop-mode/*-st[art,op].

# I run Arch Linux, so it uses systemctl to do everything.  It won't be hard
# to adapt to BSD (Slackware) or SYSV (Debian) style initscripts.

# By: The Doctor <drwho at virtadpt dot net>

# Variables
# Edit as appropriate.
SERVICES="avahi-daemon cups cups-browsed syslog-ng"
SYSTEMCTL="/usr/bin/systemctl"

# Core code.
# This script will only get called by laptop-tools with two options, 'start'
# and 'stop'.
if [ "$i" == "" ]; then
    echo "ERROR: This script must be called with 'start' or 'stop'."
    exit 1
    fi

for i in $SERVICES; do
    $SYSTEMCTL $1 $i.service
    done

# End of script.

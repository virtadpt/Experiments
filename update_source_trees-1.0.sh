#!/bin/sh

# update_source_trees.sh - Shell script for OpenBSD that updates the source
#	tree for the systemware and the ports collection.  You'll have to
#	configure it by editing two variables (CVSROOT and BRANCH).  Yeah, it's
#	quick and dirty - I use it to maintain my lab servers.

# by:	The Doctor [412/724/301/703]
#		<drwho (at) squirrelkiller (dot) virtadpt (dot) net>
#		(Antispam: I don't kill squirrels.)
#	PGP key id: 807B17C1
#	PGP key fingerprint: 7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF 2B 807B 17C1

# License: GPL

# v1.0	-Initial release.  It works in my lab.

# TODO	-Detect whether or not the root user is running this script and act
#	 appropriately.

# Set the CVS root directory to pull updates from.
export CVSROOT=<OpenBSD CVS mirror server>

# Set the branch tag to work with.
export BRANCH=OPENBSD_x_y

# Try to update the systemware source code.  If it doesn't exist yet, check
# it out.
if [ -f /usr/src/Makefile ]; then
	cd /usr/src
	cvs update -r$BRANCH -Pd
	echo "System source tree updated."
else
	cd /usr
	cvs checkout -r$BRANCH -P src
	echo "System source tree checked out."
fi

# Try to update the ports collection.  If it hasn't been pulled down yet, then
# pull the latest version out of CVS.
if [ -f /usr/ports/README ]; then
	cd /usr/ports
	cvs update -r$BRANCH -Pd
	echo "OpenBSD ports collection updated."
else
	cd /usr
	cvs checkout -r$BRANCH -P ports
	echo "OpenBSD ports collection checked out."
fi

# End of script.
exit 0

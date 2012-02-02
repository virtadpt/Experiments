#!/bin/bash

# make_iso.sh - Shell script that automates the construction of ISO-9660 disk
#		images.  Takes two command line arguments a full path to the
#		final .iso image and the directory of files to burn.  Also
#		accepts a --help/-h/-? option to display online help.
#
# by: The Doctor [412/724/301/703] <drwho (at) virtadpt (dot) net>
#	PGP key id: 807B17C1
#	PGP key fingerprint: 7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF2B 807B 17C1
#
# v1.0	-Initial release.
#
# TODO	-Make this script a little more sane: Add some checking of arguments
#	 passed to the script, stuff like that.
#	-Make it possible for the user to fine-tune the arguments passed to
#	 mkisofs.

# Variables.
OPTIONS="-f -J -l -r"
IMAGE="-o $1"
FILES=$2

# Core code.
# Catch a request for help.
for arg in $*; do
	case "${arg}" in
		--help|-h|-?)
			echo
			echo "USAGE: $0 /destination/image.iso /files/to/burn"
			echo
			exit 1
			;;
	esac
done

# Check the number of command line arguments passed.  We need at least two.
if [ "$#" -lt 2 ]; then
	echo
	echo "ERROR: Missing command line arguments."
	echo "$0 --help for online documentation."
	echo
	exit 1
	fi

# Make sure that mkisofs is in the current path.  If it's not, ABEND.
which mkisofs > /dev/null
mkisofs_found=$?
if [ "$mkisofs_found" -gt 0 ]; then
	echo "ERROR: mkisofs not found in your \$PATH variable."
	echo
	exit 1
	fi

# Make the .iso image and be done with it.
echo ".iso image: $IMAGE"
echo "Files to burn: $FILES"
echo

echo "Now generating ISO-9660 image $IMAGE"
mkisofs $OPTIONS $IMAGE $FILES

# End of script.
exit 0

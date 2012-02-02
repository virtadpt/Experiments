#!/bin/bash

# Script to update the mirror of https://torproject.org/ on Leandra and then
# push the changes out to tormirror.virtadpt.net.
# This script must run every six hours.

# The Doctor <drwho at virtadpt dot net>
# 0x807B17C1 / 7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF2B 807B 17C1

SOURCE="rsync://rsync.torproject.org/tor"
LOCAL="/home/tormirror/tor-mirror"
REMOTE="tormirror.virtadpt.net"
USER="tormirror"
SERVER="asuncion.dreamhost.com"

# Update the local mirror first.
rsync -av --delete $SOURCE $LOCAL

# Push updates to the mirror at Dreamhost.
rsync -e ssh -avz --delete $LOCAL $USER@$SERVER:$REMOTE

# Fin.
exit 0

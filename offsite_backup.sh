#!/bin/bash

# When Duplicity is run, it checks the destination filesystem to see if there
# are any backup signatures or file databases there.  If there are, it assumes
# an incremental backup.  If not, it assumes an initial full backup.

# Account ID, application key, and bucket.
ID="01234567890a"
KEY="0123456789abcdef0123456789abcdef0123456789a"
BUCKET="blogposttestbucket"

# Encryption passphrase for backed up files.
PASSPHRASE="This is where the passphrase to encrypt your data goes."

echo "Beginning system backup to Backblaze."
echo

# /home
# This stanza shows how to exclude arbitrary directories.  You can copy it as
# many times as you need, tweaking each copy to fit.  Note that the directory
# /var/cache/duplicity needs to exist (create it if it doesn't), it needs to
# be owned root:root, and it needs to be set mode 0750.
echo "Backing up /home."
sudo PASSPHRASE=$PASSPHRASE duplicity -v4 --tempdir /var/tmp \
    --exclude /home/bots/Downloads \
    --exclude /home/network-mounts \
    --archive-dir /var/cache/duplicity \
    /home b2://$ID:$KEY@$BUCKET/home

# /opt
# This stanza shows how to specify the temporary and Duplicity archive
# directories that should be used during the backup.  Again, you can copy this
# block of code as many times as you need to specify locations to back up,
# tweaking the specifics as necessary.
echo "Backing up /opt."
sudo PASSPHRASE=$PASSPHRASE duplicity -v4 --tempdir /var/tmp \
    --archive-dir /var/cache/duplicity \
    /opt b2://$ID:$KEY@$BUCKET/opt

# /var
# This stanza shows how to back up your /var directory without accidentally
# backing up Duplicity's tempfiles and making your backups even longer.
echo "Backing up /var."
sudo PASSPHRASE=$PASSPHRASE duplicity -v4 --tempdir /var/tmp \
    --exclude /var/tmp \
    --archive-dir /var/cache/duplicity \
    /var b2://$ID:$KEY@$BUCKET/var

# Delete backups older than one month to free up space.  Note that this will
# not damage your backups; Duplicity is smart enough to not erase backup files
# that constitute part of a full backup.
echo "Deleting oldest backups."
sudo PASSPHRASE=$PASSPHRASE duplicity remove-older-than 1M -v4 \
    --tempdir /var/tmp --archive-dir /var/cache/duplicity \
    b2://$ID:$KEY@$BUCKET
echo

# Clean up any tempfiles and old database files in the b2 bucket.  This also
# tells the B2 service to purge any deleted files to reclaim storage space so
# you won't continue to be charged for them.
echo "Cleaning up the storage bucket."
sudo PASSPHRASE=$PASSPHRASE duplicity cleanup -v4 \
    --tempdir /var/tmp --archive-dir /var/cache/duplicity \
    b2://$ID:$KEY@$BUCKET
echo

exit 0


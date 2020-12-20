#!/usr/bin/env bash

# Pelican timed posting script.  Run as a cronjob once an hour/day/whatever,
# checks out the repo, and looks for posts that are tagged as "scheduled,"
# which isn't actually a recognized Pelican tag.  For every scheduled post
# that it finds, it fuzzes out the datestamp in the file, checks it against
# the current datestamp, and if they match changes the tag from "scheduled"
# to "published," rebuilds the site, and deploys it to Dreamhost.

# by: The Doctor [412/724/301/703/415/510] (drwho at virtadpt dot net)
#     PGP fingerprint: <7960 1CDC 85C9 0B63 8D9F  DD89 3BD8 FF2B 807B 17C1>

# TODO:
# - 

HOME="/home/drwho"
TMP="$HOME/tmp"
TODAY=$(date +%Y-%m-%d)

# Name of the blog.
BLOG="antarctica.starts.here"

# Name of blog template.
TEMPLATE="pelican-html5up-striped"

# Path to the Git repository.
GIT_REPO="$HOME/$BLOG"

# Path to the blog template's Git repository.
TEMPLATE_REPO="$HOME/$TEMPLATE"

# Pull in the Python environment.
. $HOME/pelican/bin/activate
echo -n "Pelican version: "
pelican --version

# First let's make sure there are no stale copies of the repository laying
# around.
echo "Cleaning out stale repo checkouts."
cd $TMP
rm -rf $BLOG

# Clone the repositories.
git clone $GIT_REPO
cd $BLOG
git clone $TEMPLATE_REPO

# Build a list of scheduled posts.
echo "Searching for scheduled posts..."
cd content/
grep -Hi '^Status: scheduled' *.md | awk -F: '{print $1}' > timed_posts.txt

# Roll through the files in the content directory and set up the ones that
# are supposed to be posted.
set ANYTHING_TO_POST
for i in `cat timed_posts.txt`; do
    POST_DATE=`grep -i '^Date: ' $i | awk '{print $2}'`
    if [ $POST_DATE == $TODAY ]; then
        mv $i $i.bak
        sed 's/Status: scheduled/Status: published/' $i.bak > $i
        ANYTHING_TO_POST=1
        echo "Found a timed post!"
    fi
done
cd ..

# Save ourselves some time by not continuing if there's nothing to post.
if [ ! $ANYTHING_TO_POST ]; then
    echo "There isn't anything to post today."
    exit 0
fi

# I don't feel like copying stuff out of the Makefile right now.
# Just use the Makefile.
if [ $ANYTHING_TO_POST ]; then
    echo "Building and deploying website."
    make html

    # If you've added new targets to the Makefile, you'll want to start
    # altering the script here.
    make deploy
fi

# Commit the edited file to the local copy of the repo and then push it
# so that we have a sense of state.
if [ $ANYTHING_TO_POST ]; then
    echo
    echo "Committing the now-posted articles."
    git commit -a -m "Committing timed posts for $TODAY."
    git push
fi

# Fin.
exit 0


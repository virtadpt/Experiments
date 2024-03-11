#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 :

# upload_wiki_pages_to_bookstack.py - Takes a bunch of .md files in a
#   directory (like those from Pepperminty Wiki) and uploads them one at a
#   time to a Bookstack install.  Uses the Bookstack Python module.  This
#   script needs edited to configure the URL of your Bookstack wiki, the
#   api key, and the api secret (per https://demo.bookstackapp.com/api/docs).
#   You'll have to organize them yourself after that.
#
# Called like this: ./upload_wiki_pages_to_bookstack.py wiki/*.md
#
# Bookstack API documentation can be found at your Bookstack wiki, URI
# /api/docs.
#
# by: The Doctor <drwho at virtadpt dot net>

# License: Good Luck With That Public License
#          (https://github.com/me-shaon/GLWTPL)

# Load modules.
import json
import random
import sys
import time

# https://github.com/coffeepenbit/bookstack
import bookstack

# Constants.
base_url = "https://bookstack.wiki.example.com/"
token_id = "MrThePlagueSomethingWeirdIsGoingOn"
token_secret = "AsInWhatYouHaplessTechnoWeenie"

# Global constants
default_book_id = 1
priority = 15

# Global variables.
api = None
filename = ""
page_title = ""
page_content = ""

# Core code...
try:
    api = bookstack.BookStack(base_url, token_id=token_id,
        token_secret=token_secret)
    print("Got API connection to %s." % base_url)
except:
    print("Unable to get API connection to %s." % base_url)
    sys.exit(1)

# Seed the RNG.
random.seed()

# Generate API methods.
api.generate_api_methods()

# Loop through the wiki pages specified on the command line.
print("Okay, let's do this.")
for filename in sys.argv:
    payload = {}

    # Turn the filename into the page title.
    page_title = filename.split(".")[0]

    # Read in the file's contents.
    with open(filename, "r") as wikipage:
        page_content = wikipage.read()

    # Build the new page payload.
    payload["book_id"] = default_book_id
    payload["name"] = page_title
    payload["markdown"] = page_content

    # Send the page to the API endpoint.
    try:
        api.post_pages_create(payload)
        print("Successfully uploaded wiki page %s." % filename)

        # Sleep for a variable period of time to keep from hitting the WAF.
        time.sleep(random.randrange(5, 30))
    except:
        print("Unable to upload wiki page %s." % filename)

# Fin.
sys.exit(0)


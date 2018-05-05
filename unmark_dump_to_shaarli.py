#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# vim: set expandtab tabstop=4 shiftwidth=4 :

# unmark_dump_to_shaarli.py - Takes a JSON dump from Unmark and pumps the
#   entries, one at a time, into a Shaarli instance.

# By: The Doctor

# License: GPLv3

# v1.0 - Initial release.

# TO-DO:

# Load modules.
import argparse
import json
import jwt
import logging
import os.path
import requests
import sys
import time

# Constants.

# Global variables.
argparser = None
args = None
loglevel = None
jsonfile = None
bookmarks = {}
new_bookmark = {}
jwt_headers = {}
payload = {}
jwt_token = None
headers = {}
request = None

# Functions.

# Figure out what to set the logging level to.  There isn't a straightforward
# way of doing this because Python uses constants that are actually integers
# under the hood, and I'd really like to be able to do something like
# loglevel = 'logging.' + loglevel
# I can't have a pony, either.  Takes a string, returns a Python loglevel.
def process_loglevel(loglevel):
    if loglevel == "critical":
        return 50
    if loglevel == "error":
        return 40
    if loglevel == "warning":
        return 30
    if loglevel == "info":
        return 20
    if loglevel == "debug":
        return 10
    if loglevel == "notset":
        return 0

# Core code...
# Set up a command line argument parser.
argparser = argparse.ArgumentParser(description="A command line utility which takes a JSON dump from Unmark and pumps it into a Shaarli instance using the API.")
argparser.add_argument("--loglevel", action="store", default="info",
    help="Valid log levels: critical, error, warning, info, debug, notset.  Defaults to info.")

argparser.add_argument("--apikey", action="store", required=True,
    help="API key for a Shaarli instance.")

argparser.add_argument("--url", action="store", required=True,
    help="Full URL to a Shaarli instance.  Must include the /api/v1 bit.")

argparser.add_argument("--bookmarks", action="store", required=True,
    help="Full path to a JSON document containing an Unmark dump.")

argparser.add_argument("--dryrun", action="store_true", default=False,
    help="If set, the utility will not try to write anything.")

argparser.add_argument("--delay", action="store", type=float, default=2.5,
    help="Number of seconds to wait in between requests.  Defaults to 2.5.")

# Parse the argument vector.
args = argparser.parse_args()

# Set up logging.
loglevel = process_loglevel(args.loglevel.lower())
logging.basicConfig(level=loglevel, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Make sure the bookmarks file exists.
if not os.path.exists(args.bookmarks):
    logger.error("Unable to open Unmark bookmarks dump " + args.bookmarks + ".")
    sys.exit(1)

# Read in the Unmark JSON dump.
with open(args.bookmarks, "r") as jsonfile:
    bookmarks = json.load(jsonfile)

# Build the JWT headers.
jwt_headers["alg"] = "HS512"
jwt_headers["typ"] = "JWT"

# Set the content type header.
headers["Content-Type"] = "application/json"

# Roll through each link in the JSON document.
for link in bookmarks["export"]["marks"]:

    # Construct a new Shaarli bookmark.
    new_bookmark["url"] = link["url"]
    new_bookmark["title"] = link["title"]
    new_bookmark["private"] = True

    # Because Unmark has some annoying bugs, you can't count on links having
    # descriptions (notes) set.  Be careful when trying to extract them.  We
    # also clear the pound sounds out because, in Unmark, hashtags go in the
    # freetext notes as well as a separate list of strings.
    if link["notes"]:
        new_bookmark["description"] = link["notes"].replace("#", "")
    else:
        new_bookmark["description"] = ""

    # Figure out what the tags are on the Unmark link, extract them, and push
    # them into a list for Shaarli to ingest.
    new_bookmark["tags"] = []
    for tag in link["tags"].keys():
        new_bookmark["tags"].append(tag)
    logger.debug("New Shaarli bookmark: " + str(new_bookmark))

    # Build the JWT payload.  The IAT time must be in UTC!
    payload["iat"] = int(time.mktime(time.localtime()))
    #logger.debug("Value of payload: " + str(payload))

    # Build a JWT token.
    jwt_token = jwt.encode(payload, args.apikey, algorithm="HS512",
        headers=jwt_headers)
    #logger.debug("Value of jwt_token: " + jwt_token)

    # Set the authorization header.
    headers["Authorization"] = "Bearer " + jwt_token

    # Send the new link to Shaarli if this isn't a dry run.
    if not args.dryrun:
        logger.info("Sending link " + str(new_bookmark["url"]))
        response = requests.post(args.url+"/links",
            data=json.dumps(new_bookmark), headers=headers)
        logger.debug(json.dumps(response.json()))
    else:
        logger.info("Not sending link because this is a dry run.")

    # Sleep or a couple of seconds so we don't overwhelm the server.
    time.sleep(args.delay)

# Fin.
sys.exit(0)


#!/bin/bash

# This is an event hook for the various things that automated tools need.  The
# idea is simple, tools can call  ~enwikt/dumpevents/dumpevents.sh EVENT ARGS
# And all the tools that are waiting for that event can be started with those
# ARGS (normally a file name)
# 
# This should be easier than constantly polling, though obviously something
# will need to start off the chain.

event=$1
shift
path=`dirname $0`/..

case $event in

    # A new xml dump has been downloaded!
    new-dump)
        # Create and publish definition dumps 5-10mins
        $path/listdefns/create.sh "$@"

        ;;
    # A new definition dump has been created!
    new-defns)
        # Update [[WT:STATS]] 5mins
        $path/wiktstats/create.sh "$@"

        ;;
    *)
        echo "Invalid event '$event'"
esac

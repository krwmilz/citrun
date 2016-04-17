#!/bin/sh

# This script exists so that continuous integration has a single point of entry
# for building packages on all platforms.

uname_lc=`uname | tr '[:upper:]' '[:lower:]'`
(cd $uname_lc && sh pkg.sh)

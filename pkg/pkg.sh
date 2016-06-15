#!/bin/sh

# This script exists so that continuous integration has a single point of entry
# for building packages on all platforms.

uname_lc=`uname | tr '[:upper:]' '[:lower:]'`
if [ ! -d $uname_lc ]; then
	echo Error: Need packaging directory for "$uname_lc"
	exit 1;
fi

if [ "${1}" != "citrun" -a "${1}" != "ccitrunrun" ]; then
	echo Error: package name must be \'citrun\' or \'ccitrunrun\'
	exit 2;
fi

(cd $uname_lc && sh pkg.sh ${1})

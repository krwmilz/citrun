#!/bin/sh

ver=0

# We need to share /usr/ports with other users
umask 002

echo archiving
(cd .. && git archive --prefix=citrun-$ver/ -o pkg/citrun-$ver.tar.gz HEAD)

if [ "`uname`" == "OpenBSD" ]; then
	echo creating OpenBSD package
	if [ ! -d /usr/ports ]; then
		echo error: check out /usr/ports first
		exit 1
	fi
	cur_dir=`pwd`
	# OpenBSD port building stuff needs to know where home is
	export PORTSDIR_PATH="/usr/ports:$cur_dir"
	# Tarball is located here
	export DISTDIR=$cur_dir
	# Disable tarball checksumming.
	# Continuous integration does not like this kind of stuff.
	export NO_CHECKSUM=1
	make -C devel/citrun clean=all
	make -C devel/citrun package
else
	echo error: `uname` needs package magic
fi

echo done

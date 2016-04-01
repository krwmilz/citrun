#!/bin/sh

ver=0

echo archiving
git archive --format=tar.gz --prefix=citrun-$ver/ HEAD > pkg/citrun-$ver.tar.gz

if [ "`uname`" == "OpenBSD" ]; then
	echo creating OpenBSD package
	if [ ! -d /usr/ports ]; then
		echo error: check out /usr/ports first
		exit 1
	fi
	pkg_dir=`pwd`/pkg
	# OpenBSD port building stuff needs to know where home is
	export PORTSDIR_PATH="/usr/ports:$pkg_dir"
	# Tarball is located here
	export DISTDIR=$pkg_dir
	# Disable tarball checksumming.
	# Continuous integration does not like this kind of stuff.
	export NO_CHECKSUM=1
	make -C pkg/devel/citrun clean=all
	make -C pkg/devel/citrun package
else
	echo error: `uname` needs package magic
fi

echo done

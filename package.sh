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
	export PORTSDIR_PATH="/usr/ports:$pkg_dir"
	export DISTDIR=$pkg_dir
	make -C pkg/devel/citrun clean=all
	make -C pkg/devel/citrun package
fi

echo done

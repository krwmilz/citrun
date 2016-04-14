#!/bin/sh -e

portname="citrun"

if [ "`uname`" != "OpenBSD" ]; then
	echo "not making OpenBSD package on `uname`"
	exit 1
fi

export PORTSDIR_PATH="`pwd`:/usr/ports"
export NO_CHECKSUM=1
# Always re-fetch the latest sources
rm /usr/ports/distfiles/citrun-0.tar.gz
make -C devel/$portname clean=all
make -C devel/$portname package

doas pkg_delete citrun
doas pkg_add -Dunsigned -r /usr/ports/packages/`uname -m`/all/${portname}-0.tgz

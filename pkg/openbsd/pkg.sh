#!/bin/sh -e

ver=0
pkgname="ccitrunrun"
distname="${pkgname}-${ver}"
distfile="$distname.tar.gz"

if [ "`uname`" != "OpenBSD" ]; then
	echo "not making OpenBSD package on `uname`"
	exit 1
fi

# Git won't archive the whole tree unless its called in the root..
(cd ../../ && git archive --prefix=$distname/ -o /usr/ports/distfiles/$distfile HEAD)

export PORTSDIR_PATH="`pwd`:/usr/ports"
export NO_CHECKSUM=1
make -C devel/$pkgname clean=all
make -C devel/$pkgname package

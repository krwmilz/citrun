#!/bin/sh

set -e
ver=0

echo archiving
(cd .. && git archive --prefix=citrun-$ver/ -o pkg/citrun-$ver.tar.gz HEAD)

if [ "`uname`" == "OpenBSD" ]; then
	echo OpenBSD detected

	if [ ! -d ports ]; then
		echo downloading OPENBSD_5_8 stable ports tree
		curl -O http://ftp.openbsd.org/pub/OpenBSD/5.8/ports.tar.gz
		echo ..extracting
		tar xzf ports.tar.gz

		echo overlaying CVS metadata and getting latest patches
		cvs -qd anoncvs@anoncvs.usa.openbsd.org:/cvs get -rOPENBSD_5_8 -P ports
	else
		echo assuming ports/ tree already checked out
	fi

	echo copying port files into place
	rm -rf ports/devel/citrun
	cp -R openbsd ports/devel/citrun

	mkdir -p ports/distfiles
	mv citrun-$ver.tar.gz ports/distfiles/

	echo creating package from citrun-$ver.tar.gz
	export PORTSDIR=`pwd`/ports
	# Disable tarball checksumming.
	export NO_CHECKSUM=1
	make -C ports/devel/citrun clean=all
	make -C ports/devel/citrun package
else
	echo error: `uname` needs package magic
fi

echo done

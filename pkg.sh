#!/bin/sh

set -e
set -x

# Single point of entry for building packages on all platforms.
#
if [ "${1}" != "citrun" -a "${1}" != "ccitrunrun" ]; then
	exit 2;
fi

portname="${1}"
uname=`uname`

if [ "$uname" = "OpenBSD" ]; then
	pkg_path=/usr/ports/packages/`uname -m`/all/${portname}-0.tgz

	# Make sure package building doesn't rely on anything that's already installed
	doas pkg_delete $portname || true
	rm -f $pkg_path

	# Don't check checksums as this script is used for continuous integration
	export PORTSDIR_PATH="`pwd`/openbsd:/usr/ports"
	export NO_CHECKSUM=1

	# Always re-fetch the latest sources
	rm -f /usr/ports/distfiles/${portname}-0.tar.gz

	# The 'test' target will do a full build first
	make -C openbsd/devel/$portname clean=all
	make -C openbsd/devel/$portname test
	make -C openbsd/devel/$portname package

	doas pkg_add -Dunsigned -r $pkg_path

elif [ "$uname" = "Darwin" ]; then
	sudo port uninstall $portname

	sudo port -v -D darwin/devel/citrun clean
	sudo port -v -D darwin/devel/citrun test
	sudo port -v -D darwin/devel/citrun install

elif [ "$uname" = "Linux" ]; then
	echo ""

else
	echo Error: Can\'t package for unknown system \"$uname\"
	exit 1;
fi

# Reset end to end report when new packages are installed.
rm -f e2e_report.txt

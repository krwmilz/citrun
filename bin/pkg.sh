#!/bin/sh -e

# Single point of entry for building packages on all platforms.
#
[ "${1}" != "citrun" -a "${1}" != "ccitrunrun" ] && exit 2

portname="${1}"
uname=`uname`

if [ "$uname" = "OpenBSD" ]; then
	pkg_path=/usr/ports/packages/`uname -m`/all/${portname}-*.tgz

	# Make sure package building doesn't rely on anything that's already installed
	doas pkg_delete $portname || true
	rm -f $pkg_path

	# Don't check checksums as this script is used for continuous integration
	export PORTSDIR_PATH="`pwd`/bin/openbsd:/usr/ports"
	export NO_CHECKSUM=1

	# Always re-fetch the latest sources
	rm -f /usr/ports/distfiles/${portname}-*.tar.gz

	# The 'test' target will do a full build first
	make -C bin/openbsd/devel/$portname clean=all
	make -C bin/openbsd/devel/$portname build
	make -C bin/openbsd/devel/$portname package

	doas pkg_add -Dunsigned -r $pkg_path
	mv $pkg_path bin/

elif [ "$uname" = "Darwin" ]; then
	sudo port uninstall $portname

	sudo port -v -D darwin/devel/citrun clean
	sudo port -v -D darwin/devel/citrun build
	sudo port -v -D darwin/devel/citrun install

	cp /opt/local/var/macports/software/citrun/citrun-0.0_0.darwin_15.x86_64.tbz2 .

elif [ "$uname" = "Linux" ]; then
	sudo dpkg -r $portname || true

	tmpdir=`mktemp -d`
	trap "rm -rf $tmpdir" EXIT

	curl -o $tmpdir/citrun_0.orig.tar.gz http://cit.run/src/citrun-0.tar.gz
	(cd $tmpdir && tar xzf citrun_0.orig.tar.gz)

	(cd $tmpdir/citrun-0 && debuild -us -uc)

	sudo dpkg -i $tmpdir/citrun_0-1_amd64.deb
	cp $tmpdir/citrun_0-1_amd64.deb .

else
	echo Error: Can\'t package for unknown system \"$uname\"
	exit 1;
fi

# Reset end to end report when new packages are installed.
rm -f ../tt/report.txt

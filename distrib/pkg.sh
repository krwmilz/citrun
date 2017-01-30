#!/bin/sh -eu

uname=`uname`
if [ $uname = "OpenBSD" ]; then
	cp -R distrib/openbsd/* /usr/ports/devel/citrun/

	export NO_CHECKSUM=1
	rm -f /usr/ports/distfiles/citrun-*.tar.gz
	make -C /usr/ports/devel/citrun clean

	make -C /usr/ports/devel/citrun package

	make -C /usr/ports/devel/citrun clean
	rm -f /usr/ports/distfiles/citrun-*.tar.gz

elif [ $uname = "Darwin" ]; then
	sudo port uninstall citrun

	sudo port -v -D darwin/devel/citrun clean
	sudo port -v -D darwin/devel/citrun build
	sudo port -v -D darwin/devel/citrun install

	cp /opt/local/var/macports/software/citrun/citrun-0.0_0.darwin_15.x86_64.tbz2 bin/

elif [ $uname = "Linux" ]; then
	sudo dpkg -r citrun || true

	tmpdir=`mktemp -d`
	trap "rm -rf $tmpdir" EXIT

	curl -o $tmpdir/citrun_0.orig.tar.gz http://cit.run/src/citrun-0.tar.gz
	(cd $tmpdir && tar xzf citrun_0.orig.tar.gz)

	(cd $tmpdir/citrun-0 && debuild -us -uc)

	sudo dpkg -i $tmpdir/citrun_0-1_amd64.deb
	cp $tmpdir/citrun_0-1_amd64.deb .
else
	echo "Error: Can't package for unknown system '$uname'"
	exit 1;
fi

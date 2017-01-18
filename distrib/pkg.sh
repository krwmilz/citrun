#!/bin/sh -eu

uname=`uname`
if [ $uname = "OpenBSD" ]; then
	# Packaging might have bad interactions with an already installed
	# citrun. For now prevent that from happening.
	if pkg_info citrun > /dev/null 2>&1; then
		echo Please uninstall citrun before packaging.
		exit 1
	fi

	rm -rf /usr/ports/devel/citrun
	cp -R distrib/openbsd /usr/ports/devel/citrun

	export NO_CHECKSUM=1
	rm -f /usr/ports/distfiles/citrun*.tar.gz

	make -C /usr/ports/devel/citrun clean=all
	make -C /usr/ports/devel/citrun package
	make -C /usr/ports/devel/citrun clean
	exit 0

elif [ $uname = "Darwin" ]; then
	sudo port uninstall citrun

	sudo port -v -D darwin/devel/citrun clean
	sudo port -v -D darwin/devel/citrun build
	sudo port -v -D darwin/devel/citrun install

	cp /opt/local/var/macports/software/citrun/citrun-0.0_0.darwin_15.x86_64.tbz2 bin/
	exit 0

elif [ $uname = "Linux" ]; then
	sudo dpkg -r citrun || true

	tmpdir=`mktemp -d`
	trap "rm -rf $tmpdir" EXIT

	curl -o $tmpdir/citrun_0.orig.tar.gz http://cit.run/src/citrun-0.tar.gz
	(cd $tmpdir && tar xzf citrun_0.orig.tar.gz)

	(cd $tmpdir/citrun-0 && debuild -us -uc)

	sudo dpkg -i $tmpdir/citrun_0-1_amd64.deb
	cp $tmpdir/citrun_0-1_amd64.deb .
	exit 0
fi

echo "Error: Can't package for unknown system '$uname'"
exit 1;

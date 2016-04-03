#!/bin/sh

set -e
ver=0

echo archiving
(cd .. && git archive --prefix=citrun-$ver/ -o citrun-$ver.tar.gz HEAD)

if [ "`uname`" == "OpenBSD" ]; then
	echo OpenBSD detected

	if [ ! -d ports ]; then
		echo downloading OPENBSD_5_8 stable ports tree
		curl -O http://ftp.openbsd.org/pub/OpenBSD/5.8/ports.tar.gz
		echo ..extracting
		tar xzf ports.tar.gz

		#echo overlaying CVS metadata and getting latest patches
		#cvs -qd anoncvs@anoncvs.usa.openbsd.org:/cvs get -rOPENBSD_5_8 -P ports
	else
		echo assuming ports/ tree already checked out
	fi

	echo copying port files into place
	rm -rf ports/devel/citrun
	cp -R openbsd ports/devel/citrun

	mkdir -p ports/distfiles
	mv ../citrun-$ver.tar.gz ports/distfiles/

	echo creating package from citrun-$ver.tar.gz
	export PORTSDIR=`pwd`/ports
	export NO_CHECKSUM=1
	make -C ports/devel/citrun clean=all
	make -C ports/devel/citrun package

elif [ "`uname`" == "Darwin" ]; then
	rm -rf Citrun.app citrun_rw_img.dmg Citrun-$ver.dmg

	# Recompile from a fresh tarball
	tar xzf ../citrun-$ver.tar.gz
	rm ../citrun-$ver.tar.gz
	(cd citrun-$ver && jam)

	mkdir Citrun.app
	mkdir Citrun.app/Contents

	# Start out with a standard unix style install
	(cd citrun-$ver && PREFIX=../Citrun.app/Contents jam install)

	(cd Citrun.app/Contents && mv bin MacOS)
	(cd Citrun.app/Contents && mv lib/* MacOS/)
	(cd Citrun.app/Contents && mv man Reources)

	cp osx/Info.plist Citrun.app/Contents/

	# In case this didn't happen last time
	umount /Volumes/_Packager || true
	hdiutil create -size 32m -fs HFS+ -volname "_Packager" citrun_rw_img.dmg
	hdiutil attach citrun_rw_img.dmg

	# Figure out what device we just mounted
	DEVS=$(hdiutil attach citrun_rw_img.dmg | cut -f 1)
	DEV=$(echo $DEVS | cut -f 1 -d ' ')

	cp -R Citrun.app /Volumes/_Packager/

	hdiutil detach $DEV
	hdiutil convert citrun_rw_img.dmg -format UDZO -o Citrun-$ver.dmg
else
	echo error: `uname` needs package magic
fi

echo done

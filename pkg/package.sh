#!/bin/sh

set -e
ver=0

echo archiving
(cd .. && git archive --prefix=citrun-$ver/ -o citrun-$ver.tar.gz HEAD)

if [ "`uname`" == "Darwin" ]; then
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
	umount /Volumes/Citrun || true
	hdiutil create -size 32m -fs HFS+ -volname "Citrun" citrun_rw_img.dmg
	hdiutil attach citrun_rw_img.dmg

	# Figure out what device we just mounted
	DEVS=$(hdiutil attach citrun_rw_img.dmg | cut -f 1)
	DEV=$(echo $DEVS | cut -f 1 -d ' ')

	cp -R Citrun.app /Volumes/Citrun/

	hdiutil detach $DEV
	hdiutil convert citrun_rw_img.dmg -format UDZO -o Citrun-$ver.dmg
else
	echo error: `uname` needs package magic
fi

echo done

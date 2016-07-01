#!/bin/sh

set -e
set -x

portname="${1}"
pkg_path=/usr/ports/packages/`uname -m`/all/${portname}-0.tgz

# Make sure package building doesn't rely on anything that's already installed
doas pkg_delete $portname || true
rm -f $pkg_path

# Don't check checksums as this script is used for continuous integration
export PORTSDIR_PATH="`pwd`:/usr/ports"
export NO_CHECKSUM=1

# Always re-fetch the latest sources
rm -f /usr/ports/distfiles/${portname}-0.tar.gz

# The 'test' target will do a full build first
make -C devel/$portname clean=all
make -C devel/$portname test
make -C devel/$portname package

doas pkg_add -Dunsigned -r $pkg_path
rm -f ../../e2e_report.txt

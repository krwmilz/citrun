#!/bin/sh

set -e
set -x

portname="${1}"

sudo port uninstall $portname

rm /opt/local/var/macports/distfiles/$portname/$portname-0.tar.gz

port -v -D devel/citrun clean
sudo port -v -D devel/citrun install

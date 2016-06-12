#!/bin/sh

set -e
set -x

portname="${1}"

sudo port uninstall $portname

sudo port -v -D devel/citrun clean
sudo port -v -D devel/citrun test
sudo port -v -D devel/citrun install

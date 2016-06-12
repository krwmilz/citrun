#!/bin/sh

set -e
set -x

portname="${1}"

sudo port uninstall $portname

sudo port -v -D devel/citrun clean --all
sudo port -v -D devel/citrun install

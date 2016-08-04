#!/bin/sh

echo 1..2

out=`./src/citrun-wrap -v`

[ $? -eq 1 ] && echo ok 1 - return code
[ "$out" = "usage: citrun-wrap <build cmd>" ] && echo ok 2 - stdout

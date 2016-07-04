#!/bin/sh

sed -e "/<span class=\"stale ${1}/d" -i.bak index.html

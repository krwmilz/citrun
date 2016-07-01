#!/bin/sh

sed -e "s%stale ${1}\">stale%${1}\"><a href=\"/pkg/${2}\">test report</a>%" -i index.html

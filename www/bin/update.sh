#!/bin/sh

sed -e "s%stale ${1}\">stale%${1}\">e2e <a href=\"/pkg/${2}\">report</a>%" -i index.html

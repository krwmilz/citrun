#!/bin/sh -eu

mkdir -p www/man
for man in *.1; do
        mandoc -Thtml -I os="TempleOS 5.01" -Ostyle=/citrun.css -Oman=%N.%S.html \
		$man > www/man/`basename $man`.html
done

scp -p -r www/* 0x30.net:/var/www/htdocs/citrun.com/

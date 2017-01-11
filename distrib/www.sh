#!/bin/sh -e

mkdir -p www/man

mandoc_cmd="mandoc -Thtml -Ostyle=/citrun.css -Oman=%N.%S.html"
for man in *.1; do
        $mandoc_cmd $man > www/man/`basename $man`.html
done

scp -r www/* 0x30.net:/var/www/htdocs/citrun.com/

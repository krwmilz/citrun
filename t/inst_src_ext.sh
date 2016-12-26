#!/bin/sh -u
#
# Check that the advertised source file extensions work.
#
. t/utils.subr
plan 18

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         1 Lines of source code
EOF

# Check supported extensions.
for ext in c cc cxx cpp; do
	touch main.$ext
	ok "is extension .$ext compiled successfully" cc -c main.$ext

	ok "is citrun_check successful" citrun_check -o check.out
	strip_millis check.out
	ok "citrun_check diff" diff -u check.good check.out

	rm main.$ext citrun.log check.out main.o
done

# Check unsupported extensions.
for ext in C; do
	touch main.$ext

	ok "is extension .$ext compiled successfully" cc -c main.$ext
	ok_program "is citrun_check exit code 1" 123 "" citrun_check -o check.out

	rm main.$ext main.o
done

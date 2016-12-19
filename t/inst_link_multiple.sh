#!/bin/sh -u
#
# Check that linking more than one instrumented object file together works.
#
. t/utils.subr
plan 4


cat <<EOF > one.c
void second_func();

int main(void) {
	second_func();
	return 0;
}
EOF

cat <<EOF > two.c
void third_func();

void second_func(void) {
	third_func();
	return;
}
EOF

cat <<EOF > three.c
void third_func(void) {
	return;
}
EOF

ok "is compile ok" citrun-wrap cc -o main one.c two.c three.c
ok "running citrun-check" citrun-check -o check.out

cat <<EOF > check.good
Summary:
         3 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
        18 Lines of source code
         3 Function definitions
         1 Return statement values
         2 Call expressions
        13 Total statements
EOF

strip_millis check.out
ok "citrun-check diff" diff -u check.good check.out

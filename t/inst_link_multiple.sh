#
# Check that linking more than one instrumented object file together works.
#
echo 1..4
. test/utils.sh

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

cat <<EOF > Jamfile
Main program : one.c two.c three.c ;
EOF

$CITRUN_TOOLS/citrun-wrap jam && echo "ok - source compiled"
$CITRUN_TOOLS/citrun-check > check.out && echo ok

cat <<EOF > check.good
Summary:
         3 Source files used as input
         1 Application link commands
         3 Rewrite successes
         3 Rewritten source compile successes

Totals:
        18 Lines of source code
         3 Function definitions
         1 Return statement values
         2 Call expressions
        13 Total statements
EOF

check_diff 4

#
# Test that the basic static structure of the shared memory region is what we
# expect.
#
echo 1..4
. test/project.sh

./program 45 &
pid=$!

$TEST_TOOLS/citrun-dump | grep -e "Versi" -e "Progr" -e "Translat" > dump.out
$TEST_TOOLS/citrun-dump -f > filelist.out

kill -USR1 $pid
wait
[ $? -eq 0 ] && echo ok 2 - program return code after SIGUSR1

cat <<EOF > dump.good
Version: 0.0
Program name: program
Translation units: 3
EOF
test_diff 3 "citrun-dump output" dump.out dump.good

cat <<EOF > filelist.good
one.c 34
three.c 9
two.c 11
EOF
filelist_diff 4

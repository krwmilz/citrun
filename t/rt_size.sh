#
# Test that the runtime shared file size is what we expect.
#
echo 1..2
. test/project.sh

./program 1

stat -f %z runtime/* > size
echo "16384" > size.good

test_diff 2 "shared memory file size" size.good size

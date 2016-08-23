#
# Check that the runtime version of the shared memory file is what we expect.
#
echo 1..2
. test/project.sh

./program 2

xxd -p -l 2 runtime/* > hex_version
echo "0000" > hex_version.good

test_diff 2 "shared memory file version" hex_version.good hex_version

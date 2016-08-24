#
# Test that translation unit file names are what we expect.
#
echo 1..2
. test/project.sh

./program 1

$CITRUN_TOOLS/citrun-dump -f > filelist.out

cat <<EOF > filelist.good
one.c 26
three.c 9
two.c 11
EOF
filelist_diff 2

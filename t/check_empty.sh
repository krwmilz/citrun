#
# Verify the output when 0 citrun.log files are found.
#
echo 1..2
. test/utils.sh

$CITRUN_TOOLS/citrun-check > check.out

cat <<EOF > check.good
No log files found.
EOF

diff -u check.good check.out && echo ok

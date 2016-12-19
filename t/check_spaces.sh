#!/bin/sh -u
#
# Verify citrun-check can handle paths with spaces when counting log file.
#
. t/utils.subr
plan 2

enter_tmpdir

ok "are dirs with spaces in name created" mkdir dir\ a dir\ b
echo "Found source file" > dir\ a/citrun.log
echo "Found source file" > dir\ b/citrun.log
ok "is citrun-check successful" citrun-check
#ok "is citrun-check with path successful" citrun-check dir\ a/

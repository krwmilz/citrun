#!/bin/sh -u
#
# Verify citrun_check can handle paths with spaces when counting log file.
#
. t/utils.subr
plan 2


ok "are dirs with spaces in name created" mkdir dir\ a dir\ b
echo "Found source file" > dir\ a/citrun.log
echo "Found source file" > dir\ b/citrun.log
ok "is citrun_check successful" citrun_check
#ok "is citrun_check with path successful" citrun_check dir\ a/

#!/bin/sh -u
#
# Verify citrun-check can handle paths with spaces when counting log file.
#
. t/libtap.subr
. t/utils.subr
plan 2

modify_PATH
enter_tmpdir

ok "is dir with spaces in name created" mkdir dir\ a dir\ b
touch dir\ a/citrun.log
touch dir\ b/citrun.log
ok "is citrun-check successful" citrun-check .

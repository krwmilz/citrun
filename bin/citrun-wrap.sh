#!/bin/sh

export CITRUN_PATH="%PREFIX%/share/citrun"
export CITRUN_LIB="%PREFIX%/lib/libcitrun.a"
export PATH="$CITRUN_PATH:$PATH"

exec $@

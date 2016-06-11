#!/bin/sh

export CITRUN_PATH="%PREFIX%/share/citrun"
export CITRUN_LIB="%PREFIX%/lib/libcitrun.%SHLIB_SUF%"
export PATH="$CITRUN_PATH:$PATH"

exec $@

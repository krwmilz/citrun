#!/bin/sh

export CITRUN_PATH="%PREFIX%/share/citrun"
export PATH="$CITRUN_PATH:$PATH"

exec $@

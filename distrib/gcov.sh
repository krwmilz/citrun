#!/bin/sh -e

export CITRUN_COVERAGE=1
CFLAGS="-coverage -O0 -g" jam -j4

prove || true
# prove tt

gcov -o src src/rt.c
egcov -r src/*.cc

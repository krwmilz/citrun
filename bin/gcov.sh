#!/bin/sh -e

export CITRUN_COVERAGE=1
CFLAGS="-coverage -O0 -ggdb" jam -j4

prove
prove tt

gcov -o src src/runtime.c
egcov -r src/*.cc

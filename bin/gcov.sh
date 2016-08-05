#!/bin/sh -e

git clean -fdx

export CITRUN_COVERAGE=1
CFLAGS="-coverage -O0 -ggdb" jam -j4

prove

gcov -o lib lib/runtime.c
egcov -r src/*.cc

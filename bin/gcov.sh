#!/bin/sh -e

export COVERAGE=1
CFLAGS="-coverage -O0 -ggdb" jam -j4
gcov -o lib lib/runtime.c
egcov -r src/*.cc

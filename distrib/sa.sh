#!/bin/sh -e

export CITRUN_SA=1
scan-build -o html --use-c++=eg++ jam -j4

package tlib::program;
use strict;
use warnings;

# This module builds the test program when it's used.
system("cd tlib/program && ../../src/citrun-wrap jam");

1;

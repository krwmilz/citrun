package t::program;
use strict;
use warnings;

# This module builds the test program when it's used.
system("cd t/program && ../../src/citrun-wrap jam");

1;

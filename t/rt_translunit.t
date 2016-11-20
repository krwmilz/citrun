#
# Test that the shared memory translation units are what we expect.
#
use strict;
use warnings;
use Test::More tests => 7;
use t::program;
use t::shm;
use t::tmpdir;

my $tmp_dir = t::tmpdir->new();
t::program->new($tmp_dir);

my $ret = system("$tmp_dir/program 10");
is $ret >> 8,	0,	"is program exit code 0";

my $shm = t::shm->new($tmp_dir);

my ($tu1, $tu2, $tu3) = @{ $shm->{translation_units} };
is	$tu1->{size},	9,	"is translation unit 1 9 lines";
is	$tu1->{comp_file_name},	'print.c',	'is compiler file name right';
like	$tu1->{abs_file_path},	qr/.*print.c/,	'is absolute file path believable';

is	$tu2->{size},	11,	"is translation unit 2 9 lines";
is	$tu2->{comp_file_name},	'fib.c',	'is compiler file name right';
like	$tu2->{abs_file_path},	qr/.*fib.c/,	'is absolute file path believable';

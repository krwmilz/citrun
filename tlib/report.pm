package tlib::report;
use strict;

use List::MoreUtils qw( each_array );

sub new {
	my ($class, $name, $num_tests) = @_;

	my $self = {};
	bless($self, $class);

	$self->{name} = $name;
	$self->{desc} = [];
	$self->{vanilla} = [];
	$self->{citrun} = [];

	$self->{start_time} = time;
	$self->{num_tests} = $num_tests;

	return $self;
}

sub add {
	my ($self, $field, $desc) = @_;

	push @{ $self->{$field} }, ($desc);
}

sub write_header {

	open (E2E_HEADER, ">", "tt/report.txt") or die "$!";

	format E2E_HEADER =
E2E TEST REPORT
===============

SYSTEM INFO
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"started at:", `date`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"host:", `uname -n`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<
"os:", `uname -s`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<
"version:", `uname -r`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<
"arch:", `uname -m`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<
"user:", `logname`
     @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<
"citrun version:", 0

.
	write E2E_HEADER;
	close E2E_HEADER;
}

sub DESTROY {
	my ($self) = @_;

	my @diff;
	my @desc	= @{ $self->{desc} };
	my @vanilla	= @{ $self->{vanilla} };
	my @citrun	= @{ $self->{citrun} };

	my $it = each_array( @vanilla, @citrun );
	while ( my ($x, $y) = $it->() ) {
		push @diff, $y * 100.0 / $x - 100.0;
	}

	if (! -e "tt/report.txt") {
		write_header();
	}

	open (E2E_REPORT, ">>", "tt/report.txt") or die "$!";

	format E2E_REPORT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<
$self->{name}
     @<<<<<<<<<<<<<<  @#### s
"duration:", time - $self->{start_time}
     @<<<<<<<<<<<<<< @#####
"tests planned:", $self->{num_tests}

                                      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
"vanilla", "citrun", "diff (%)"
     ---------------------------------------------------------------------
     @<<<<<<<<<<<<<<<<<<<<<<<<<<      @>>>>>>>>>   @>>>>>>>>>        @>>>> ~~
shift(@desc), shift(@vanilla), shift(@citrun), shift(@diff)

.

	write E2E_REPORT;
	close E2E_REPORT;
}

1;

package Test::Report;
use strict;

use List::MoreUtils qw( each_array );

sub new {
	my ($class, $name) = @_;

	my $self = {};
	bless($self, $class);

	$self->{name} = $name;
	$self->{desc} = [];
	$self->{vanilla} = [];
	$self->{citrun} = [];

	return $self;
}

sub add {
	my ($self, $field, $desc) = @_;

	push @{ $self->{$field} }, ($desc);
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

	open (E2E_REPORT, ">>", "e2e_report.txt") or die "$!";

	format E2E_REPORT =
@>>>>>>>>>>>>>>>>>>>>
$self->{name}
======================
#      @<<<<<<<<<<<<<<<<<<<  @##.##
# "60 data calls (s):", $data_call_dur
#      @<<<<<<<<<<<<<<<<<<<  @#####
# "tests ok:", $num_tests
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

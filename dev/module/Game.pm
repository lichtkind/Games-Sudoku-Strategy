use v5.18;
use warnings;
use lib '.';
use Benchmark;

use Grid;

package Game;


sub new {
    my ($pkg) = @_;
    bless { grid => Grid->new() }
}

sub load {
    my ($self, $file) = @_;

    # . or - to 0
    # remove sonderzeichen
    # to AoA
}

sub save {
    my ($self, $file) = @_;
}

sub solve {
    my ($self) = @_;

}

sub full_analysis {
    my ($self) = @_;

}

sub find {
    my ($self) = @_;

}

1;

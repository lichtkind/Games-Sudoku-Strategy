use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use Benchmark;


package GroupDigitMemory;

sub new      { __PACKAGE__->restate( [0..9] )         }
sub clone    { __PACKAGE__->restate( $_[0]->state() ) }
sub restate  { ref $_[0] ?  @{$_[0]} = @{$_[1]} : bless $_[1] }
sub state    { [@{$_[0]}] }

sub get_solution { $_[0][0] }
sub set_solution {
    my ($self, $digit) = @_;
    return 0 if $self->get_solution or not $self->has_candidate($digit); # don't override solution, use unsolve
    $self->[$digit] = 0;
    $self->[0] = $digit;
}
sub unsolve {
    my ($self) = @_;
    my $digit = $self->[0];
    $self->[0] = 0;
    $self->[$digit] = $digit;
}

sub has_candidate {
    my ($self, $digit) = @_;
    return unless _is_digit( $digit );
    $self->[$digit];
}
sub add_candidate {
    my ($self, $digit) = @_;
    return unless _is_digit( $digit );
    return 0 if $self->[$digit] == $digit;
    $self->[$digit] = $digit;
}
sub remove_candidate {
    my ($self, $digit) = @_;
    return unless _is_digit( $digit );
    my $ret = $self->[$digit];
    $self->[$digit] = 0;
    $ret;
}
sub candidate_count {
    my ($self) = @_;
    scalar grep {$_} @$self[1..9];
}
sub get_candidates {
    my ($self, $bits) = @_;
    my @c = $bits ? (map {$self->[$_] > 0 ? 1 : 0} 1..9) : (grep {$self->[$_]} 1..9);
    wantarray ? @c : join '', @c;
}
sub get_candidates_missing {
    my ($self, $bits) = @_;
    my @c = $bits ? (map {$self->[$_] == 0 ? 1 : 0} 1..9) : (grep {$self->[$_] == 0} 1..9);
    wantarray ? @c : join '', @c;
}


sub _is_digit { defined $_[0] and int $_[0] == $_[0] and $_[0] > 0 and $_[0] < 10 }

1;

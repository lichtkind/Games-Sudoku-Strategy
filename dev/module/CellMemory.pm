use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use utf8;


package CellMemory;
use List::Util qw/sum/;


sub new      { __PACKAGE__->restate( [0..9] )         }
sub state    { [@{$_[0]}] }
sub restate  { ref $_[0] ?  @{$_[0]} = @{$_[1]} : bless [@{$_[1]}] }
sub clone    { __PACKAGE__->restate( $_[0]->state() ) }
sub hash {
    my ($self) = @_;
    my $sol = $self->get_solution;
    chr( $sol ? 48 + $sol : 512 + sum( map {2**($_-1)} $self->get_candidates ));
}
sub rehash {
    my ($pkg, $hash) = @_;
    my $self = ref $pkg ? $pkg : bless [];
    my $nr = ord $hash;
    @$self = $nr < 512
           ? ($hash, (0) x 9)
           : (0, map {($nr & 2**($_-1)) ? $_ : 0} 1 .. 9);
    $self;
}

sub get_solution { $_[0][0] } # works also as ->solved
sub solvable { my @c = $_[0]->get_candidates; @c and @c == 1 }
sub solve {
    my ($self, $digit) = @_;
    return 0 if $self->get_solution; # don't override solution

    my @cand = $self->get_candidates;
    unless (defined $digit){ # when no solution given take last candidate
        return 0 if @cand > 1;
        $digit = $cand[0];
    }
    return 0 if $digit ne int $digit or $digit < 1 or $digit > 9;
    return 0 unless $self->[$digit]; # solution must be active candidate
    @$self = ($digit, (0) x 9);
    @cand > 1 ? [grep {$_ != $digit} @cand] : $digit;
}
sub unsolve {
    my ($self) = @_;
    return 0 unless $self->solution;
    my $digit = $self->[0];
    $self->[$digit] = $digit;
    $self->[0] = 0;
    $digit;
}
sub has_digit {
    my ($self, $digit) = @_;
    return unless _is_digit( $digit );
    ($self->[$digit] or $self->[0] == $digit) ? 1 : 0;
}
sub has_candidate {
    my ($self, $digit) = @_;
    return unless _is_digit( $digit );
    $self->[$digit] ? 1 : 0;
}
sub add_candidate {
    my ($self, $digit) = @_;
    $digit = abs $digit;
    return 0 if not _is_digit( $digit ) or $self->get_solution() or $self->[$digit] == $digit;
    $self->[$digit] = $digit;
}
sub remove_candidate {
    my ($self, $digit) = @_;
    return if $self->get_solution();
    $digit = abs $digit;
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
    return if $self->get_solution and not defined $bits;
    my @c = $bits ? (map {$self->[$_] > 0 ? 1 : 0} 1..9) : (grep {$self->[$_]} 1..9);
    wantarray ? @c : join '', @c;
}
sub get_candidates_missing {
    my ($self, $bits) = @_;
    return if $self->get_solution and not defined $bits;
    my @c = $bits ? (map {$self->[$_] == 0 ? 1 : 0} 1..9) : (grep {$self->[$_] == 0} 1..9);
    wantarray ? @c : join '', @c;
}

sub _is_digit { defined $_[0] and int $_[0] == $_[0] and $_[0] > 0 and $_[0] < 10 }

1;

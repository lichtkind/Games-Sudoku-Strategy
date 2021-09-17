use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use CellMemory;
use GroupDigitMemory;

package GroupMemory;
use List::Util qw/min/;

sub new {
    my ($pkg, $group) = @_;
    my $self = bless { digit => [], pos => [], group => $group, msg => 0 };
    $self->{'pos'}[$_] = $self->{'group'}{'pos'}[$_]{'mem'}  for 1 .. 9;
    $self->reset();
}
sub reset {                         # called when new game is loaded
    my ($self) = @_;
    $self->{'pos'}[0] = CellMemory->new();
    $self->{'digit'}[$_] = CellMemory->new() for 0 .. 9;
    for my $pos (1 .. 9) {
        my $cell = $self->{'pos'}[$pos];
        if ($cell->get_solution){ $self->add_solution( $cell->solution, $pos )                      }
        else                    { $self->remove_candidate( $_, $pos ) for $cell->get_candidates_missing }
    }
    $self->{'msg'} = 0;
    $self;
}
########################################################################
sub cell     { $_[0]->{'group'}{'pos'}[$_[1]] }
########################################################################
sub add_solution {
    my ($self, $digit, $pos) = @_;
    return 0 if $self->{'pos'}[$pos]->get_solution() != $digit;
    $self->{'msg'} = 0;
    $self->{'pos'}[0]->remove_candidate( $pos );
    $self->{'digit'}[0]->remove_candidate( $digit );
    my $p = $self->{'digit'}[$digit]->solve( $pos );
    $self->{'digit'}[$_]->remove_candidate( $pos ) for 1 .. 9;
    return $digit unless ref $p;
    $self->{'pos'}[$_]->remove_candidate( $digit ) for @$p;
    map {$self->cell($_)} @$p;
}
sub remove_solution {
    my ($self, $digit, $pos) = @_;
    return 0 if $self->{'pos'}[$pos]->get_solution();
    $self->{'msg'} = 0;
    $self->{'pos'}[0]->add_candidate( $pos );
    $self->{'digit'}[0]->add_candidate( $digit );
    $self->{'digit'}[$digit]->unsolve();
}
sub add_candidate {
    my ($self, $digit, $pos) = @_;
    $digit = abs $digit;
    return 0 unless $self->{'pos'}[$pos]->has_candidate( $digit );
    $self->{'msg'} = 0;
    $self->{'digit'}[$digit]->add_candidate( $pos );
    $digit;
}
sub remove_candidate {
    my ($self, $digit, $pos) = @_;
    $digit = abs $digit;
    return 0 if $self->{'pos'}[$pos]->has_candidate( $digit );
    $self->{'msg'} = 0;
    $self->{'digit'}[$digit]->remove_candidate( $pos );
    $digit;
}
########################################################################

sub find_progress {
    my ($self) = @_;
    return @{$self->{'msg'}} if ref $self->{'msg'};
    my $unsolved = { 'pos'   => [scalar $self->{'pos'}[0]->get_candidates('bits'),   $self->{'pos'}[0]->get_candidates()  ],
                     'digit' => [scalar $self->{'digit'}[0]->get_candidates('bits'), $self->{'digit'}[0]->get_candidates()] };
    my ($edge, $part_graph, $prog_cand, @msg ) = ({}, {}, {});
    for my $pos ($self->{'pos'}[0]->get_candidates_missing()){
        my $sol = $self->{'pos'}[$pos]->get_solution;
        my @cand = $self->{'digit'}[$sol]->get_candidates;
        next unless @cand;
        my @cmd = map { [$self->cell($_), -$sol] } @cand;
        my $removal_reason = "$self->{group}{type} $self->{group}{nr} already has solved digit $sol on pos $pos";
        push @msg, Message->new( \@cmd, [$self->cell($pos), $sol], $removal_reason, ['gc', $self->{'group'}{'type'}, $self->{'group'}{'nr'} ]);
    }
    for my $digit (1 .. 9){
        my @pos = $self->{'digit'}[$digit]->get_candidates;
        next unless @pos == 1 and not $self->{'digit'}[$digit]->get_solution;
        my $solution_reason = "$self->{group}{type} $self->{group}{nr} has a single candidate with digit $digit on pos $pos[0]";
        push @msg, Message->new( [ $self->cell($pos[0]), $digit ], 
                                 [ map { [$self->cell($_), $digit] } grep {$_ != $pos[0]} 1..9 ], 
                                 $solution_reason, ['gs', $self->{'group'}{'type'}, $self->{'group'}{'nr'} ]);
    }
    for my $src ('pos', 'digit'){
        my $deg = $self->{$src}[0]->candidate_count;
        next if $deg < 3;
        for my $nr (1 .. $deg) {
            my $d = $unsolved->{$src}[$nr];
            $edge->{$src}{'bits'}[$nr]  = $self->{$src}[ $d ]->get_candidates('bits');
            $edge->{$src}{'count'}[$nr] = count_bits( $edge->{$src}{'bits'}[$nr] );
        }
        $part_graph->{$src}[1] = [ map  { [ $edge->{$src}{'bits'}[$_], $_    ] }  # bitmask, @v id, last v nr
                                   grep {   $edge->{$src}{'count'}[$_] < $deg  }  1 .. $deg ];
        for my $length (2 .. min(4, $deg-1)){
            for my $pg (@{$part_graph->{$src}[ $length-1 ] }){
                for my $next_v ($pg->[-1]+1 .. $deg){
                    next if $edge->{$src}{'count'}[$next_v] == $deg;
                    my $new_pg = [@$pg, $next_v];
                    $new_pg->[0] |= $edge->{$src}{'bits'}[$next_v];
                    push @{$prog_cand->{$src}}, $new_pg if count_bits( $new_pg->[0] ) == $length;
                    push @{$part_graph->{$src}[ $length ]}, $new_pg;
                    $edge->{$src}{'map'}[ join '', map { $unsolved->{$src}[$_] }  @$new_pg[1 .. $#$new_pg] ] = $new_pg->[0];
    }   }   }   }
    for my $src ('pos', 'digit'){
        my $dest = $src eq 'pos' ? 'digit' : 'pos';
        my $deg = $self->{$src}[0]->candidate_count;
        my @cand = $self->{$src}[0]->get_candidates;
        for my $block (@{$prog_cand->{$src}}){
            my @target = @{bits_to_candidates( $block->[0] )};
            my $target = bits_to_candidate_str( $block->[0] );
            my $reflection = $edge->{ $dest }{'map'}[ $target ] // $unsolved->{$src}[0];
            next if count_bits( $reflection ) < @$block or ($deg/2) < (@$block-1); # reject closed blocks (reflection == block size)
            my $rest = bits_to_candidates( int_to_bits( bits_to_int($reflection) - bits_to_int($block->[0]) ) );
            shift @$block; # block indices are indices amoung left indices, others are absolut i
            my @abs_block = map {$cand[$_-1]} @$block;
            my (@cmd, @trigger);
            for my $target_digit (@target){
                for my $tail_pos (@$rest) { push @cmd,    [$tail_pos, $target_digit] if $self->{$src}[$tail_pos]->has_candidate( $target_digit) }
                for my $block_pos (@abs_block){push @trigger,[$block_pos,$target_digit] if $self->{$src}[$block_pos]->has_candidate($target_digit) }
            }
            my ($posi, $digi) = $src eq 'pos' ? (0,1) : (1,0);
            @cmd =     map { [$self->cell($_->[$posi]), -$_->[$digi]] } @cmd;
            @trigger = map { [$self->cell($_->[$posi]), $_->[$digi]] } @trigger;
             my $removal_reason = "$self->{group}{type} $self->{group}{nr} $src block:";
            $removal_reason .= " $_" for @abs_block;
            push @msg, Message->new( \@cmd, \@trigger, $removal_reason, ['gb', $src, $self->{'group'}{'type'}, $self->{'group'}{'nr'} ]);
    }   }
    $self->{'msg'} = \@msg;
    @msg;
}


########################################################################
my (%count_bits, %b2c, %b2cs, %c2b, %c2i, %i2c, %b2i, %i2b, %comb_of_l);
for my $nr (0..511){
    my $bit_str = sprintf "%09b", $nr;
    my @bits = split '', $bit_str;
    $count_bits{$bit_str} = int grep {$_} @bits;
    my @cand = grep {$_} map {$bits[($_-1)] ? $_ : 0} 1..9;
    my $cand = join '', @cand;
    $b2c{$bit_str} = $cand;
    $b2cs{$bit_str} = \@cand;
    $c2b{$cand} = $bit_str;
    $c2i{$cand} = $nr;
    $b2i{$bit_str} = $nr;
    $i2b{$nr} = $bit_str;
}
sub count_bits            { $count_bits{$_[0]} }
sub bits_to_candidates    { $b2cs{$_[0]}       }
sub bits_to_candidate_str { $b2c{$_[0]}        }
sub candidates_to_bits    { $c2b{$_[0]}        }
sub candidates_to_int     { $c2i{$_[0]}        }
sub int_to_candidates     { $i2c{$_[0]}        }
sub bits_to_int           { $b2i{$_[0]}        }
sub int_to_bits           { $i2b{$_[0]}        }

1;

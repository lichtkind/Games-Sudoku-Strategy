use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Message;
use CellMemory;

package GroupIntersectionGrid;
use List::Util qw/sum/;

########################################################################

sub new {
    my ($pkg, $group_list, $type, $start_line_nr) = @_;   # type = 'vertical'|'horizontal' , index = 1|4|7
    return unless defined $start_line_nr and ($start_line_nr == 1 or $start_line_nr == 4 or $start_line_nr == 7);
    return unless $type eq 'vertical' or $type eq 'horizontal';
    my $self = { type => $type, line_type => $type eq 'horizontal' ? 'row' : 'column', start_line_nr => $start_line_nr,
                 cand_count => [[[],[],[]],[[],[],[]],[[],[],[]]],     msg => 0,
                 line_last_cand_box => [[],[],[]], box_last_cand_line => [[],[],[]] };
    for my $line_index (0 .. 2){
        my $line_nr = $start_line_nr + $line_index;
        @{$self->{'line_last_cand_box'}[$line_index]} = ((0)x10);
        @{$self->{'box_last_cand_line'}[$line_index]} = ((0)x10);
        for my $box_index (0 .. 2){
            @{$self->{'cand_count'}[$line_index][$box_index]} = ((0)x10);
            push @{$self->{'cell'}[$line_index][$box_index]}, $group_list->[$line_nr]{'pos'}[$_] for _line_pos($box_index);
            $_->{'intersection'}{$type} = $self for @{$self->{'cell'}[$line_index][$box_index]};
        }
    }
    GroupIntersectionGrid::reset( $self );
    bless $self;
}
########################################################################

sub reset {                         # called when new game is loaded
    my ($self) = @_;
    for my $line_index (0 .. 2){
        for my $box_index (0 .. 2){
            for my $digit (1 .. 9){
                $self->{'cand_count'}[$line_index][$box_index][$digit]
                    = sum( map {$_->{'mem'}->has_candidate($digit)} @{$self->{'cell'}[$line_index][$box_index]} );
            }
        }
    }    
    for my $index (0 .. 2){
        for my $digit (1 .. 9){
            $self->{'line_last_cand_box'}[$index][$digit] = _last_cand($self->{'cand_count'}[$index][0][$digit].
                                                                       $self->{'cand_count'}[$index][1][$digit].
                                                                       $self->{'cand_count'}[$index][2][$digit]);
            $self->{'box_last_cand_line'}[$index][$digit] = _last_cand($self->{'cand_count'}[0][$index][$digit]. 
                                                                       $self->{'cand_count'}[1][$index][$digit]. 
                                                                       $self->{'cand_count'}[2][$index][$digit]);
        }
    }
    $self->{'msg'} = 0;
    $self;
}

sub update {                        # called after cell change
    my ($self, $row, $col, @digit) = @_;
    ($row, $col) = ($col, $row) if $self->{'type'} eq 'vertical';
    my $line_index = $row - $self->{'start_line_nr'};
    my $box_index = _pos2index($col);
    for my $d (@digit){
        $d = abs $d;
        $self->{'cand_count'}[$line_index][$box_index][$d] 
            = sum( map {$_->{'mem'}->has_candidate($d)} @{$self->{'cell'}[$line_index][$box_index]} );
        $self->{'line_last_cand_box'}[$line_index][$d] = _last_cand($self->{'cand_count'}[$line_index][0][$d].
                                                                    $self->{'cand_count'}[$line_index][1][$d].
                                                                    $self->{'cand_count'}[$line_index][2][$d]);
        $self->{'box_last_cand_line'}[$box_index][$d]  = _last_cand($self->{'cand_count'}[0][$box_index][$d]. 
                                                                    $self->{'cand_count'}[1][$box_index][$d]. 
                                                                    $self->{'cand_count'}[2][$box_index][$d]);
    }
    $self->{'msg'} = 0;
    $self;
}

sub find_progress {
    my ($self) = @_;
    return @{$self->{'msg'}} if ref $self->{'msg'};
    my @msg;
    for my $line_index (0,1,2){
        for my $digit (1..9){
            my $box_index = $self->{'line_last_cand_box'}[$line_index][$digit]-1;
            next unless $box_index > -1;                            # lines has one last intersection with candidates
            next if $self->{'box_last_line'}[$box_index][$digit];   # box alread cleared of all but last candidates
            my @trigger = map {[$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, $digit]} 
                          grep {$_->{'mem'}->has_candidate($digit)}           @{$self->{'cell'}[$line_index][$box_index]};
            my @cmd = ();
            for my $other_line_index (0,1,2){
                next if $other_line_index == $line_index
                    or not $self->{'cand_count'}[$other_line_index][$box_index][$digit];
                push @cmd, map {[$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, -$digit]} 
                           grep {$_->{'mem'}->has_candidate($digit)}              @{$self->{'cell'}[$other_line_index][$box_index]};
            }
            my $cell = $self->{'cell'}[$line_index][$box_index][0];
            my $reason = "last candidates of digit $digit in $self->{line_type} ".$cell->{$self->{'line_type'}}{'nr'}.' intersect only with box '.$cell->{'box'}{'nr'};
            push @msg, Message->new( \@cmd, \@trigger, $reason, ['gi', $self->{'type'}]);
        }
    }
    for my $box_index (0,1,2){
        for my $digit (1..9){
            my $line_index = $self->{'box_last_line'}[$box_index][$digit];
            next unless $line_index;                                      # box has one last intersection with candidates
            next if $self->{'line_last_cand_box'}[$line_index][$digit];   # line alread cleared of all but last candidates
            my @trigger = map {[$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, $digit]} 
                          grep {$_->{'mem'}->has_candidate($digit)}           @{$self->{'cell'}[$line_index][$box_index]};
            my @cmd = ();
            for my $other_box_index (0,1,2){
                next if $other_box_index == $box_index
                    or not $self->{'cand_count'}[$line_index][$other_box_index][$digit];
                push @cmd, map {[$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, -$digit]} 
                           grep {$_->{'mem'}->has_candidate($digit)}              @{$self->{'cell'}[$line_index][$other_box_index]};
            }
            my $cell = $self->{'cell'}[$line_index][$box_index][0];
            my $reason = "last candidates of digit $digit in box $cell->{box}{nr} intersect only with $self->{line_type} ".$cell->{$self->{'line_type'}}{'nr'};
            push @msg, Message->new( \@cmd, \@trigger, $reason, ['gi', $self->{'type'}]);
        }
    }
    $self->{'msg'} = \@msg;
    @msg;
}

########################################################################
my @line_pos = ([1,2,3], [4,5,6], [7,8,9]);
my @pos2index = (0,0,0,0,1,1,1,2,2,2);
my %last_cand = ('100' => 1,'010' => 2,'001' => 3,'200' => 1,'020' => 2,'002' => 3,'300' => 1,'030' => 2,'003' => 3);
for my $d1 (0..3){
    for my $d2 (0..3){
        for my $d3 (0..3){
            my $key = $d1.$d2.$d3;
            $last_cand{$key} = 0 unless exists $last_cand{$key};
}}}
sub _last_cand        { $last_cand{$_[0]} }
sub _line_pos         { @{$line_pos[$_[0]]} }
sub _pos2index        { $pos2index[$_[0]] }

########################################################################
1;

use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Message;
use CellMemory;

package GroupIntersection;
use List::Util qw/sum/;

sub new {
    my ($pkg, $name, @cell) = @_;
    bless {name => $name, cell => [@cell], neighbour =>[], cand_count => [(3)x10], status => [ (0) x 10 ], code => 0 };
}
sub connect_with_neighbours {
    my ($self) = @_;
    $self->{'neighbour'} = $self->{'name'} =~ /\srow\s/
                         ? [[grep {$_ ne $self} @{$self->{'cell'}[1]{'box'}{'intersection'}{'horizontal'}}],
                            [grep {$_ ne $self} @{$self->{'cell'}[1]{'row'}{'intersection'}{'horizontal'}}] ]
                         : [[grep {$_ ne $self} @{$self->{'cell'}[1]{'box'}{'intersection'}{'vertical'}}],
                            [grep {$_ ne $self} @{$self->{'cell'}[1]{'col'}{'intersection'}{'vertical'}}] ];
}
sub neighbours {  @{$_[0]->{'neighbour'}[0]}[0,1], @{$_[0]->{'neighbour'}[1]}[0,1] }
sub cells      {  @{$_[0]->{'cell'}} }
########################################################################
sub get_cand_count    { $_[0]->{'cand_count'}[ $_[1] ]         }
sub update_cand_count { $_[0]->{'cand_count'}[ $_[1] ] = sum( map { $_->{'mem'}->has_candidate( $_[1] ) } $_[0]->cells ) }
sub cell_has_solution { for my $cell ($_[0]->cells) { return 1 if $cell->{'mem'}->get_solution == $_[1] } }
sub cell_has_last_cand{ (  $_[0]->get_cand_count($_[1]) and
                         ( sum( map { $_->get_cand_count($_[1]) } @{$_[0]->{'neighbour'}[0]} ) == 0 or
                           sum( map { $_->get_cand_count($_[1]) } @{$_[0]->{'neighbour'}[1]} ) == 0    )) ? 1 : 0 }

sub i_have_solution          { $_[0]->{'status'}[ $_[1] ] == 2 }
sub i_have_last_candidate    { $_[0]->{'status'}[ $_[1] ] == 1 }
sub neighbour_has_last_cand  { $_[0]->{'status'}[ $_[1] ] == -1 }
sub neighbour_has_solution   { $_[0]->{'status'}[ $_[1] ] == -2 }
sub get_status               { $_[0]->{'status'}[ $_[1] ] }
sub set_status               {
    my ($self, $digit, $status) = @_;
    $self->{'status'}[ $digit ] = $status;
    if ($status > 0){ map {$_->set_status($digit, -$status)} $self->neighbours }
}
########################################################################

sub reset {
    my ($self, $code, $stage) = @_;
    return if defined $code and $code == $self->{'code'};
    if (not defined $code) {
        $code = time+rand;  $_->reset( $code, 1 ) for $self->neighbours;
        $code = time+rand;  $_->reset( $code, 2 ) for $self->neighbours;
    } else {
        $self->{'code'} = $code;
        if ( $stage == 1){
            for my $digit (1..9){
                $self->update_cand_count( $digit );
                $self->set_status($digit, 0);
            }
            for my $cell ($self->cells){
                my $sol = $cell->{'mem'}->get_solution();
                $self->set_status($sol, 2) if $sol;
            }
        } else {
            for my $digit (1..9){
                next if $self->get_cand_count($digit) == 0 or abs($self->get_status($digit) == 2);
                $self->set_status( $digit, 1) if $self->cell_has_last_cand( $digit );
            }
        }
        $_->reset( $code, $stage ) for $self->neighbours;
    }
}
sub update {
    my ($self, $digit) = @_;
    my $old_count = $self->get_cand_count($digit);
    my $new_count = $self->update_cand_count( $digit );
    return $self->set_status($digit, 2) if $self->cell_has_solution( $digit );
    return $self->set_status($digit, 1) if $self->cell_has_last_cand( $digit );
    if    ($old_count and not $new_count) { $_->update($digit) for $self->neighbours  }
    elsif (not $old_count and $new_count) { $_->set_status($digit, 0) for $self, $self->neighbours }
}
########################################################################

sub find_progress {
    my ($self, $digit) = @_;
    my $last_cand_holder = 0;
    $last_cand_holder = $self if $self->i_have_last_candidate( $digit);
    if ($self->neighbour_has_last_cand( $digit)) {
        ($last_cand_holder) = grep { $_->i_have_last_candidate( $digit) } $self->neighbours;
    }
    if ($last_cand_holder){
        my @cmd = map { [$_, -$digit] }
                  grep { $_->{'mem'}->has_candidate( $digit ) }
                  map { $_->cells } $last_cand_holder->neighbours;
        my @trigger = map {[$_, $digit]} grep { $_->{'mem'}->has_candidate( $digit ) } $last_cand_holder->cells;
        return Message->new( \@cmd, \@trigger, $self->{'name'}, ['gi']);
    }
}

1;

__END__
    for my $col_nr (1 .. 9) {
        my $col = $grid->{'col'}[$col_nr];
        for my $row_nr (1, 4, 7) {
            $col->{'pos'}[$row_nr  ]{'intersection'}{'vertical'} =
            $col->{'pos'}[$row_nr+1]{'intersection'}{'vertical'} =
            $col->{'pos'}[$row_nr+2]{'intersection'}{'vertical'} =
                GroupIntersection->new( 'intersect col '.$col_nr.' box '.$col->{'pos'}[$row_nr]{'box'}{'nr'},
                                        $col->{'pos'}[$row_nr], $col->{'pos'}[$row_nr+1], $col->{'pos'}[$row_nr+2] );
        }
        $col->{'intersection'}{'vertical'} = [ map {$col->{'pos'}[$_]{'intersection'}{'vertical'}} 1,4,7 ];
    }
    for my $row_nr (1 .. 9) {
        my $row = $grid->{'row'}[$row_nr];
        for my $col_nr (1, 4, 7) {
            $row->{'pos'}[$col_nr  ]{'intersection'}{'horizontal'} =
            $row->{'pos'}[$col_nr+1]{'intersection'}{'horizontal'} =
            $row->{'pos'}[$col_nr+2]{'intersection'}{'horizontal'} =
                GroupIntersection->new( 'intersect row '.$row_nr.' box '.$row->{'pos'}[$col_nr]{'box'}{'nr'},
                                        $row->{'pos'}[$col_nr], $row->{'pos'}[$col_nr+1], $row->{'pos'}[$col_nr+2] );
        }
        $row->{'intersection'}{'horizontal'} = [ map {$row->{'pos'}[$_]{'intersection'}{'horizontal'}} 1,4,7 ];
    }
    for my $box (@{$grid->{'box'}}[1..9]) {
        $box->{'intersection'}{'vertical'}   = [ map {$box->{'pos'}[$_]{'intersection'}{'vertical'}}   1,2,3 ];
        $box->{'intersection'}{'horizontal'} = [ map {$box->{'pos'}[$_]{'intersection'}{'horizontal'}} 1,4,7 ];
        $_->connect_with_neighbours() for @{$box->{'intersection'}{'vertical'}}, @{$box->{'intersection'}{'horizontal'}};
    }

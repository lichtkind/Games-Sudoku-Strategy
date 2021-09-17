use v5.18;
use warnings;
use lib '.';
use Benchmark;
use GroupMemory;
use GroupIntersectionGrid;

package Grid;
use Scalar::Util qw/looks_like_number/;

my @group_type = (qw/row col box/);

########################################################################
sub new {
    my $grid = { };
    for my $group_type (@group_type){
        $grid->{$group_type}[$_] = { type => $group_type, nr => $_, 'pos' => [] } for 1 .. 9;
    }
    for my $row_nr (1 .. 9){
        for my $col_nr (1 .. 9){
            my $box_nr = 3 * int(($row_nr-1)/3) + int(($col_nr+2)/3);
            my $box_pos = 3 * (($row_nr-1) % 3) + int(($col_nr+2) % 3) + 1;
            $grid->{'row'}[$row_nr]{'pos'}[$col_nr] =
            $grid->{'col'}[$col_nr]{'pos'}[$row_nr] =
            $grid->{'box'}[$box_nr]{'pos'}[$box_pos] =
                { row => $grid->{'row'}[$row_nr], row_pos => $col_nr,
                  col => $grid->{'col'}[$col_nr], col_pos => $row_nr,
                  box => $grid->{'box'}[$box_nr], box_pos => $box_pos, mem => CellMemory->new };
        }
    }
    for my $group_type (@group_type){
        $grid->{$group_type}[$_]{'mem'} = GroupMemory->new( $grid->{$group_type}[$_] ) for 1 .. 9;
    }
    for my $nr (1, 4, 7) {
        GroupIntersectionGrid->new($grid->{'row'}, 'horizontal', $nr);
        GroupIntersectionGrid->new($grid->{'col'}, 'vertical', $nr);
    }
    bless $grid;
}
########################################################################

sub reset {
    my $self = shift;
    for my $group_type (@group_type){ $self->{$group_type}[$_]{'mem'}->reset for 1 .. 9 }
    $self->{'row'}[$_]{'pos'}[$_]{'intersection'}{'horizontal'}->reset for 2,5,8;
    $self->{'row'}[$_]{'pos'}[$_]{'intersection'}{'vertical'}->reset for 2,5,8;
    $self;
}
sub restate  {
    my ($pkg, $state) = @_;
    my $grid = Grid->new();
    for my $r (1..9) {
        for my $c (1..9) { $grid->{'row'}[$r]{'pos'}[$c]{'mem'}->restate( $state->[$r-1][$c-1] ) }
    }
    $grid->reset;
}
sub state    {
    my $self = shift;
    my $state = [];
    for my $r (1..9) {
        for my $c (1..9) { $state->[$r-1][$c-1] = $self->{'row'}[$r]{'pos'}[$c]{'mem'}->state }
    }
    $state;
}
sub rehash  {
    my ($pkg, $hash) = @_;
    my $grid = Grid->new();
    for my $r (reverse 1..9) {
        for my $c (reverse 1..9) { $grid->{'row'}[$r]{'pos'}[$c]{'mem'}->rehash( chop $hash ) }
    }
    $grid->reset;
}
sub hash {
    my $self = shift;
    my $hash = '';
    for my $r (1..9) {
        for my $c (1..9) { $hash .= $self->{'row'}[$r]{'pos'}[$c]{'mem'}->hash }
    }
    $hash;
}
sub clone    { __PACKAGE__->restate( $_[0]->state() ) }
########################################################################

sub get_group {
    my ($self, $type, $nr) = @_;
    if (looks_like_number($type) and int $type eq $type){
        ($nr, $type) = ($type, 'row');
    }
    return unless defined $nr and ($type eq 'row' or $type eq 'col' or $type eq 'box');
    $self->{$type}[$nr] if exists $self->{$type} and exists $self->{$type}[$nr];

}
sub get_cell {
    my ($self) = shift;
    my $pos = pop @_;
    my $group = $self->get_group(@_);
    return unless ref $group eq 'HASH' and defined $pos and looks_like_number($pos);
    $group->{'pos'}[$pos] if exists $group->{'pos'}[$pos];
}
########################################################################

sub add_solution {
    my ($self, $row, $col, $digit) = @_;
    my $cell = $self->get_cell($row, $col);
    return unless defined ref $cell and defined $digit;
    my $ret = $cell->{'mem'}->solve( $digit );
    return unless $ret;
    my @cmd;
    @cmd = map {[$row, $col, -$_]} @$ret if ref $ret eq 'ARRAY';
    for my $group (@group_type){
        my @cells = $cell->{$group}{'mem'}->add_solution( $digit, $cell->{$group.'_pos'} );
        next unless @cells;
        push @cmd, map {[$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, -$digit]} @cells;
    }
    $cell->{'intersection'}{$_}->update( $row, $col, $digit, map {$_->[2]} @cmd ) for qw/vertical horizontal/;
    @cmd;
}
sub remove_solution {
    my ($self, $row, $col, $digit) = @_;
    my $cell = $self->get_cell($row, $col);
    my $ret = $cell->{'mem'}->unsolve();
    return unless $ret;
    $cell->{$_}{'mem'}->remove_solution( $digit, $cell->{$_.'_pos'} ) for @group_type;
    $cell->{'intersection'}{$_}->update( $row, $col ) for qw/vertical horizontal/;
    $ret;
}
sub add_candidate {
    my ($self, $row, $col, $digit) = @_;
    $digit = abs $digit;
    my $cell = $self->get_cell($row, $col);
    return unless defined ref $cell and defined $digit;
    my $ret =  $cell->{'mem'}->add_candidate( $digit );
    return 0 unless $ret;
    $cell->{$_}{'mem'}->add_candidate( $digit, $cell->{$_.'_pos'} ) for @group_type;
    $cell->{'intersection'}{$_}->update( $row, $col, $digit ) for qw/vertical horizontal/;
    $digit;
}
sub remove_candidate {
    my ($self, $row, $col, $digit) = @_;
    $digit = abs $digit;
    my $cell = $self->get_cell($row, $col);
    return unless defined ref $cell and defined $digit;
    my $ret =  $cell->{'mem'}->remove_candidate( $digit );
    return 0 unless $ret;
    $cell->{$_}{'mem'}->remove_candidate($digit, $cell->{$_.'_pos'}) for @group_type;
    $cell->{'intersection'}{$_}->update( $row, $col, $digit ) for qw/vertical horizontal/;
    $digit;
}

sub find_next_progress {
    my ($self, $row, $col, $digit) = @_;
    my $cell = $self->get_cell($row, $col);
    $cell->{'row'}{'mem'}->find_progress, $cell->{'col'}{'mem'}->find_progress, $cell->{'box'}{'mem'}->find_progress,
    $cell->{'intersection'}{'vertical'}->find_progress( ),
    $cell->{'intersection'}{'horizontal'}->find_progress( );
}

sub find_progress {
    my ($self) = @_;
    # my %progress; values %progress;
    # find_cell_progress
    my @msg = map {my ($digit, $row, $col) = ($_->{'mem'}->get_candidates, $_->{'colpos'}, $_->{'rowpos'});
                   Message->new( [ $row, $col, $digit ], [ $row, $col, 0], "cell in row $row column $col has only candidate $digit left", ['cs' ]) }
                       grep {$_->{'mem'}->solvable} map { @{$_->{'pos'}}[1..9] } @{$self->{'row'}}[1..9];
    # cell group
    push @msg, $self->{'row'}[$_]{'mem'->find_progress() for 1..9;
    push @msg, $self->{'col'}[$_]{'mem'->find_progress() for 1..9;
    push @msg, $self->{'box'}[$_]{'mem'->find_progress() for 1..9;
    # cell group intersection
    push @msg, $self->{'row'}[$_]{'pos'}[$_]{'intersection'}{'vertical'}->find_progress() for 1,4,7;
    push @msg, $self->{'row'}[$_]{'pos'}[$_]{'intersection'}{'horizontal'}->find_progress() for 1,4,7;
    grep {ref $_} @msg;
}
########################################################################

sub eval_msg {
    my ($self, $msg) = @_;
    for my $cmd ($msg->commands){
        if ($cmd->[2] > 0){ 
            my @ret = $self->add_solution( @$cmd );
            $msg->remove_commands( $cmd ) unless $ret[0];
            next unless ref $ret[0];
            $msg->add_commands( @ret );
            $self->remove_candidate( @$_ ) for @ret;
        } else {
            $msg->remove_commands( $cmd ) unless $self->remove_candidate( @$cmd );
        }
    }
}

1;

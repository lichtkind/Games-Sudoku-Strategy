use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use GroupIntersection;
use GroupIntersectionGrid;
use Benchmark;

my $t = Benchmark->new;

my $i = GroupIntersection->new('name', {mem =>CellMemory->new}, {mem =>CellMemory->new}, {mem =>CellMemory->new});
say ref $i eq 'GroupIntersection';
say $i->get_cand_count(1) == 3;
say $i->update_cand_count(1) == 3;

my $grid = { row => [], col => [], box => [] };

for my $group_type (qw/row col box/){
    $grid->{$group_type}[$_] = { group_type => $group_type, nr => $_, 'pos' => [] } for 1 .. 9;
}
for my $row_nr (1 .. 9){
    for my $col_nr (1 .. 9){
        my $box_nr = 3 * int(($row_nr-1)/3) + int(($col_nr+2) / 3);
        my $box_pos = 3 * (($row_nr-1) % 3) + int(($col_nr+2) % 3) + 1;
        my $cell = { row => $grid->{'row'}[$row_nr], row_pos => $col_nr,
                     col => $grid->{'col'}[$col_nr], col_pos => $row_nr,
                     box => $grid->{'box'}[$box_nr], box_pos => $box_pos, mem => CellMemory->new };
        $grid->{'row'}[$row_nr]{'pos'}[$col_nr] =
        $grid->{'col'}[$col_nr]{'pos'}[$row_nr] =
        $grid->{'box'}[$box_nr]{'pos'}[$box_pos] = $cell;
    }
}

for my $col_nr (1 .. 9) {
    my $col = $grid->{'col'}[$col_nr];
    for my $row_nr (1, 4, 7) {
        $col->{'pos'}[$row_nr  ]{'intersection'}{'vertical'} =
        $col->{'pos'}[$row_nr+1]{'intersection'}{'vertical'} =
        $col->{'pos'}[$row_nr+2]{'intersection'}{'vertical'} =
            GroupIntersection->new( 'vert. intersect. col '.$col_nr.' box '.$col->{'pos'}[$row_nr]{'box'}{'nr'},
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
           GroupIntersection->new( 'horiz. intersect. row '.$row_nr.' box '.$row->{'pos'}[$col_nr]{'box'}{'nr'},
                                    $row->{'pos'}[$col_nr], $row->{'pos'}[$col_nr+1], $row->{'pos'}[$col_nr+2] );

    }
    $row->{'intersection'}{'horizontal'} = [ map {$row->{'pos'}[$_]{'intersection'}{'horizontal'}} 1,4,7 ];
}
for my $box_nr (1 .. 9) {
    my $box = $grid->{'box'}[$box_nr];
    $box->{'intersection'}{'vertical'}   = [ map {$box->{'pos'}[$_]{'intersection'}{'vertical'}}   1,2,3 ];
    $box->{'intersection'}{'horizontal'} = [ map {$box->{'pos'}[$_]{'intersection'}{'horizontal'}} 1,4,7 ];
    $_->connect_with_neighbours() for @{$box->{'intersection'}{'vertical'}}, @{$box->{'intersection'}{'horizontal'}};
}



say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->get_cand_count(1) == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->update_cand_count(1) == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_cand_count(1) == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update_cand_count(1) == 3;
$grid->{'row'}[1]{'pos'}[1]{'mem'}->remove_candidate(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->get_cand_count(1) == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->update_cand_count(1) == 2;
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->find_progress(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_cand_count(1) == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update_cand_count(1) == 2;
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->find_progress(1);
$grid->{'row'}[1]{'pos'}[2]{'mem'}->remove_candidate(1);
$grid->{'row'}[1]{'pos'}[3]{'mem'}->remove_candidate(1);
$grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->update_cand_count(1) == 2;
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'vertical'}->find_progress(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update_cand_count(1) == 0;
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->find_progress(1);
$grid->{'row'}[1]{'pos'}[$_]{'mem'}->remove_candidate(1) for 4..6;
$grid->{'row'}[1]{'pos'}[4]{'intersection'}{'horizontal'}->update(1);
my @msg = $grid->{'row'}[1]{'pos'}[4]{'intersection'}{'horizontal'}->find_progress(1);
my $msg = $msg[0];
say int @msg == 1;
say int $msg->commands == 6;
#say "..";
say int $msg->trigger == 3;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->neighbour_has_last_cand(1);
say $grid->{'row'}[1]{'pos'}[8]{'intersection'}{'horizontal'}->i_have_last_candidate(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_status(1) == -1;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_cand_count(1) == 0;
say $grid->{'row'}[1]{'pos'}[7]{'intersection'}{'horizontal'}->get_status(1) == 1;
say $grid->{'row'}[1]{'pos'}[7]{'intersection'}{'horizontal'}->get_cand_count(1) == 3;


$grid->{'row'}[1]{'pos'}[1]{'mem'}->add_candidate(1);
$grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_cand_count(1) == 1;
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->get_status(1) == 0;
say $grid->{'row'}[1]{'pos'}[7]{'intersection'}{'horizontal'}->get_status(1) == 0;
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->find_progress(1);
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->i_have_last_candidate(1);
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->neighbour_has_last_cand(1);
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->i_have_solution(1);
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->neighbour_has_solution(1);
$grid->{'row'}[1]{'pos'}[9]{'mem'}->solve(1);
$grid->{'row'}[1]{'pos'}[9]{'intersection'}{'horizontal'}->update(1);
say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->i_have_solution(1);
say $grid->{'row'}[1]{'pos'}[9]{'intersection'}{'horizontal'}->i_have_solution(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->neighbour_has_solution(1);

$grid->{'row'}[2]{'pos'}[$_]{'mem'}->remove_candidate(2) for 1..6;
$grid->{'row'}[$_]{'pos'}[$_]{'intersection'}{'horizontal'}->reset() for 2,5,8;
$grid->{'row'}[$_]{'pos'}[$_]{'intersection'}{'vertical'}->reset() for 2,5,8;

say not $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->i_have_solution(1);
say $grid->{'row'}[1]{'pos'}[9]{'intersection'}{'horizontal'}->i_have_solution(1);
say $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->neighbour_has_solution(1);
say $grid->{'row'}[2]{'pos'}[2]{'intersection'}{'horizontal'}->neighbour_has_last_cand(2);
say $grid->{'row'}[2]{'pos'}[7]{'intersection'}{'horizontal'}->i_have_last_candidate(2);
say not $grid->{'row'}[2]{'pos'}[2]{'intersection'}{'horizontal'}->i_have_solution(2);
say not $grid->{'row'}[2]{'pos'}[7]{'intersection'}{'horizontal'}->i_have_solution(2);
say not $grid->{'row'}[2]{'pos'}[2]{'intersection'}{'horizontal'}->neighbour_has_solution(2);
say not $grid->{'row'}[2]{'pos'}[7]{'intersection'}{'horizontal'}->neighbour_has_solution(2);


my @nmsg = $grid->{'row'}[2]{'pos'}[8]{'intersection'}{'horizontal'}->find_progress(2);
$msg = $nmsg[0];
say int @nmsg == 1;
say int $msg->commands == 5;
say int $msg->trigger == 3;
#say @{$nmsg[0]};

########################################################################

$grid = { row => [], col => [], box => [] };

for my $group_type (qw/row col box/){
    $grid->{$group_type}[$_] = { group_type => $group_type, nr => $_, 'pos' => [] } for 1 .. 9;
}
for my $row_nr (1 .. 9){
    for my $col_nr (1 .. 9){
        my $box_nr = 3 * int(($row_nr-1)/3) + int(($col_nr+2) / 3);
        my $box_pos = 3 * (($row_nr-1) % 3) + int(($col_nr+2) % 3) + 1;
        my $cell = { row => $grid->{'row'}[$row_nr], row_pos => $col_nr,
                     col => $grid->{'col'}[$col_nr], col_pos => $row_nr,
                     box => $grid->{'box'}[$box_nr], box_pos => $box_pos, mem => CellMemory->new };
        $grid->{'row'}[$row_nr]{'pos'}[$col_nr] =
        $grid->{'col'}[$col_nr]{'pos'}[$row_nr] =
        $grid->{'box'}[$box_nr]{'pos'}[$box_pos] = $cell;
    }
}

for my $nr (1, 4, 7) {
    GroupIntersectionGrid->new($grid->{'row'}, 'horizontal', $nr);
    GroupIntersectionGrid->new($grid->{'col'}, 'vertical', $nr);
}

say ref $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'} eq 'GroupIntersectionGrid';

$grid->{'row'}[1]{'pos'}[$_]{'mem'}->remove_candidate(1) for 1..7;
$grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->update(1,$_,1) for 1..7;
@msg = $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}->find_progress();

say $grid->{'row'}[1]{'pos'}[1] eq $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cell'}[0][0][0];
say $grid->{'row'}[1]{'pos'}[4] eq $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cell'}[0][1][0];
say $grid->{'row'}[3]{'pos'}[9] eq $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cell'}[2][2][2];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[0][0][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[0][1][1];
say 2 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[0][2][1];
say 3 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[1][0][1];
say 3 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[2][1][1];
say 3 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'cand_count'}[2][2][1];
say 3 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'line_last_cand_box'}[0][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'line_last_cand_box'}[1][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'line_last_cand_box'}[2][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'box_last_cand_line'}[0][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'box_last_cand_line'}[1][1];
say 0 ==                           $grid->{'row'}[1]{'pos'}[1]{'intersection'}{'horizontal'}{'box_last_cand_line'}[2][1];
say int @msg == 1;
my @cmd = $msg[0]->commands;
say int @cmd == 6;
say $cmd[0][0] == 2;
say $cmd[0][1] == 7;
say $cmd[0][2] == -1;
say $cmd[1][1] == 8;
say $cmd[1][2] == -1;
say $cmd[-1][0] == 3;
say $cmd[-1][1] == 9;
say $cmd[-1][2] == -1;
#say '..';
my @trigger = $msg[0]->trigger;
say int @trigger == 2;
say $trigger[0][0] == 1;
say $trigger[0][1] == 8;
say $trigger[0][2] == 1;
say $trigger[1][1] == 9;
say $trigger[1][2] == 1;

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';



use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Benchmark;
use CellMemory;
use GroupMemory;
use Message;

my $t = Benchmark->new;

my @cells = (0, map {{mem => CellMemory->new, row => {nr => 1}, col => { nr => $_} }} 1 .. 9);
my $gm = GroupMemory->new( { type => 'row', nr => 1, pos => \@cells } );
say ref $gm eq 'GroupMemory';

# reactio no solution set
say not $gm->find_progress();
my $cand = $cells[1]->{'mem'}->solve(1);
say ref $cand eq 'ARRAY';
my @cand = $gm->add_solution(1, 1);
say int @cand == 8;
say $cand[0]{'row'}{'nr'} == 1;
say $cand[0]{'col'}{'nr'} == 2;
say $cand[-1]{'row'}{'nr'} == 1;
say $cand[-1]{'col'}{'nr'} == 9;
say not $gm->find_progress();

# reaction to last cand
for (3..9){   $cells[$_]->{'mem'}->remove_candidate(2);    $gm->remove_candidate(2, $_) }
my @msg = $gm->find_progress();
say int @msg == 1;
my @cmd = $msg[0]->commands;
say @cmd == 1;
say $cmd[0][0] == 1;
say $cmd[0][1] == 2;
say $cmd[0][2] == 2;
my @trigger = $msg[0]->trigger;
say @trigger == 8;
say $trigger[0][0] ==  1;
say $trigger[0][1] ==  1;
say $trigger[0][2] ==  2;
say $trigger[-1][0] ==  1;
say $trigger[-1][1] ==  9;
say $trigger[-1][2] ==  2;
say !!$msg[0]->reason;
say $msg[0]->category eq 'gs';
say $msg[0]->sub_category eq 'row';
$cells[2]->{'mem'}->solve(2);
$gm->add_solution(2, 2);


# closed pos block
for (5..9){   $cells[3]->{'mem'}->remove_candidate($_);    $gm->remove_candidate($_, 3) }
for (5..9){   $cells[4]->{'mem'}->remove_candidate($_);    $gm->remove_candidate($_, 4) }
@msg = $gm->find_progress();
say int @msg == 1;
@cmd = $msg[0]->commands;
say int @cmd == 10;
say $cmd[0][0] == 1;
say $cmd[0][1] == 5;
say $cmd[0][2] == -3;
say $cmd[1][1] == 5;
say $cmd[1][2] == -4;
say $cmd[-1][0] == 1;
say $cmd[-1][1] == 9;
say $cmd[-1][2] == -4;
@trigger = $msg[0]->trigger;
say int @trigger == 4;
say $trigger[0][0] == 1;
say $trigger[0][1] == 3;
say $trigger[0][2] == 3;
say $trigger[1][1] == 3;
say $trigger[1][2] == 4;
say $trigger[-1][0] ==  1;
say $trigger[-1][1] ==  4;
say $trigger[-1][2] ==  4;
say !!$msg[0]->reason;
say $msg[0]->category eq 'gb';
say $msg[0]->sub_category eq 'pos';
for (5..9){   $cells[$_]->{'mem'}->remove_candidate(3);    $gm->remove_candidate(3, $_) }
for (5..9){   $cells[$_]->{'mem'}->remove_candidate(4);    $gm->remove_candidate(4, $_) }


# open digit block
for (7..9){   $cells[$_]->{'mem'}->remove_candidate(5);    $gm->remove_candidate(5, $_) }
for (8..9){   $cells[$_]->{'mem'}->remove_candidate(6);    $gm->remove_candidate(6, $_) }
for (8..9){   $cells[$_]->{'mem'}->remove_candidate(7);    $gm->remove_candidate(7, $_) }
@msg = $gm->find_progress();
say int @msg == 2;
@cmd = $msg[1]->commands;
say int @cmd == 6;
say $cmd[0][0] == 1;
say $cmd[0][1] == 5;
say $cmd[0][2] == -8;
say $cmd[1][1] == 5;
say $cmd[1][2] == -9;
say $cmd[-1][0] == 1;
say $cmd[-1][1] == 7;
say $cmd[-1][2] == -9;
@trigger = $msg[1]->trigger;
say int @trigger == 8;
say $trigger[0][0] == 1;
say $trigger[0][1] == 5;
say $trigger[0][2] == 5;
say $trigger[1][1] == 5;
say $trigger[1][2] == 6;
say $trigger[-1][0] == 1;
say $trigger[-1][1] == 7 ;
say $trigger[-1][2] == 7;
say !!$msg[1]->reason;
say $msg[1]->category eq 'gb';
say $msg[1]->sub_category eq 'digit';


# cycle pos block
@cells = (0, map {{mem => CellMemory->new, row => {nr => 1}, col => { nr => $_} }} 1 .. 9);
$gm = GroupMemory->new( { type => 'row', nr => 1, pos => \@cells } );
for (  3..9){   $cells[1]->{'mem'}->remove_candidate($_);    $gm->remove_candidate($_, 1) }
for (2,4..9){   $cells[2]->{'mem'}->remove_candidate($_);    $gm->remove_candidate($_, 2) }
for (1,4..9){   $cells[3]->{'mem'}->remove_candidate($_);    $gm->remove_candidate($_, 3) }
@msg = $gm->find_progress();
say int @msg == 1;
@cmd = $msg[0]->commands;
say int @cmd == 18;
say $cmd[0][0] == 1;
say $cmd[0][1] == 4;
say $cmd[0][2] == -1;
say $cmd[1][1] == 4;
say $cmd[1][2] == -2;
say $cmd[-1][0] == 1;
say $cmd[-1][1] == 9;
say $cmd[-1][2] == -3;
@trigger = $msg[0]->trigger;
say int @trigger == 6;
say $trigger[0][0] == 1;
say $trigger[0][1] == 1;
say $trigger[0][2] == 1;
say $trigger[1][1] == 1;
say $trigger[1][2] == 2;
say $trigger[-1][0] ==  1;
say $trigger[-1][1] ==  3;
say $trigger[-1][2] ==  3;
say !!$msg[0]->reason;
say $msg[0]->category eq 'gb';
say $msg[0]->sub_category eq 'pos';
#say '..';

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';



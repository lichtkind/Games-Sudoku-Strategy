use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Benchmark;
use Test::More;
use MessageQ;
use MessageStore;
use StateGraph;

my $t = Benchmark->new;


# check commandü
say not Message::_is_cmd({});
say not Message::_is_cmd([1,1]);
say not Message::_is_cmd([1,1,'d']);
say Message::_is_cmd([1,1,1]);

#say '..';
my $msg = Message->new([[1, 2,-3]], [[4, 5,-6]], 'reason', ['t']);
say ref $msg eq 'Message';
say not $msg->has_solution;
my @a = $msg->commands;
say int @a;
say int @{$a[0]} == 3;
say $a[0][0] == 1;
say $a[0][1] == 2;
say $a[0][2] == -3;
say $msg->reason eq 'reason';
my @c = $msg->trigger;
say int @c == 1;
say int @{$c[0]} == 3;
say $c[0][0] == 4;
say $c[0][1] == 5;
say $c[0][2] == -6;
say $msg->category eq 't';
say not $msg->sub_category;
say int @{$msg->add_commands( [1, 2, 5] )} == 2;
say $msg->has_solution;
say int @{$msg->add_commands( [1, 2, 5] )} == 2;
say int @{$msg->add_commands( [1, 2, 5] )} == 2;
say int @{$msg->remove_commands( [1, 2, -4] )} == 2;
say int @{$msg->remove_commands( [1, 2, -3] )} == 1;
say int @{$msg->add_commands( [1, 2, -3] )} == 2;
say $msg->has_solution;

my $cl = $msg->clone;
say ref $cl eq 'Message';
say $cl->reason eq 'reason';
say $cl->category eq 't';
@c = $msg->trigger;
say int @c == 1;
say int @{$c[0]} == 3;
say $c[0][0] == 4;
say $c[0][1] == 5;
say $c[0][2] == -6;
$cl->[0][0] = 9;
$cl->[1][0] = 9;
say $cl->[0][0] != $msg->[0][0];
say $cl->[1][0] != $msg->[1][0];
$cl = $msg->clone;
say $cl->[0][0][0] == $msg->[0][0][0];
say $cl->[0][0][2] == $msg->[0][0][2];
say $cl->[0][1][2] == $msg->[0][1][2];
say $cl->[1][0][2] == $msg->[1][0][2];
say $cl->[3][0]    eq $msg->[3][0];
say $cl->[6]       eq $msg->[6];
say $msg->hash eq $cl->hash;


my $q = MessageQ->new();
say ref $q eq 'MessageQ';
say not $q->can_undo;
say not $q->can_redo;
say not $q->add([]);
say not $q->can_undo;
say not $q->can_redo;
say (($q->add($msg)) == 1);
say $q->can_undo;
say not $q->can_redo;
say $q->last_element eq $msg;
say $q->undo;
say not $q->can_undo;
say $q->can_redo;
say $q->redo;
say $q->can_undo;
say not $q->can_redo;

$cl = $q->clone;
say ref $cl eq 'MessageQ';
say $cl->can_undo;
say not $cl->can_redo;
say $q->elements eq $cl->elements;



say $q->last_element->key eq $cl->last_element->key;
#say '..';
my $st = MessageStore->new();
say ref $st eq 'MessageStore';
say $st->add_msg($msg) eq $msg;
say $st->get_msg($msg->hash) eq $msg;



my $sg = StateGraph->new();
say ref $sg eq 'StateGraph';


say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';



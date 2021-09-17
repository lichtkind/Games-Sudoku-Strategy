use v5.18;
use warnings;
use lib '.';
use Benchmark;
use Grid;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $t = Benchmark->new;

my $g = Grid->new();
#say $g->hash;
my $rp = $g->get_group(1);
my $cp = $g->get_cell(1,2);
say ref $g eq 'Grid';
say ref $rp eq 'HASH';
say ref $rp->{'mem'} eq 'GroupMemory';
say $rp->{'type'} eq 'row';
say $rp->{'nr'} eq 1;
say $rp eq $cp->{'row'};

say ref $cp eq 'HASH';
say ref $cp->{'mem'} eq 'CellMemory';
say $cp->{'row'}{'nr'} == 1;
say $cp->{'row_pos'}   eq 2;
say $cp->{'col'}{'nr'} eq 2;
say $cp->{'box'}{'nr'} eq 1;
my $state = $g->state();
$cp->{'mem'}->remove_candidate(3);
my $c = $g->clone();
say ref $c eq ref $g;
say int $c ne int $g;
say not $c->get_cell('row',1,2)->{'mem'}->has_candidate(3);

my $msg = Message->new([1,1,1],[],'sol',['grid', 'check']);
say ref $msg eq 'Message';
say int ($msg->commands) == 1;
$g->eval_msg($msg);
say int ($msg->commands)== 29;

#my $cp = $g->get_cell(1,2);
#say "@$_" for @$state;
#say @{$state->[3][3]};

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';


use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Benchmark;
use CellMemory;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $t = Benchmark->new;
my $c = CellMemory->new();
say ref $c eq 'CellMemory';
say not $c->get_solution();
say not $c->solvable();
say scalar $c->get_candidates() eq '123456789';
say join( '', $c->get_candidates()) eq '123456789';
say join( '', $c->get_candidates('bits')) eq '111111111';
say scalar $c->get_candidates() eq '123456789';
say scalar $c->get_candidates('bits') eq '111111111';
say not $c->has_candidate(10);
say not $c->has_candidate(0);
say $c->has_candidate(2) > 0;
say $c->has_digit(2) > 0;
say $c->remove_candidate(2) > 0;
say scalar( $c->get_candidates ) eq '13456789';
say not $c->has_candidate(2);
say not $c->has_digit(2);
say $c->remove_candidate(2) == 0;
say $c->add_candidate(2) == 2;
say $c->has_candidate(2);
say $c->remove_candidate(2) == 2;
say not $c->get_solution();
say not $c->solvable();

my $cl = $c->clone();
say ref $cl eq 'CellMemory';
say $cl ne $c;
say scalar($cl->get_candidates ) eq '13456789';
say $cl->solve(2) eq 0;
say join( '', $cl->get_candidates()) eq '13456789';
say scalar $c->get_candidates('bits') eq '101111111';
my $cand = $cl->solve(5);
say ref $cand eq 'ARRAY';
say $cand ~~ [1,3,4,6,7,8,9];
say join( '', $cl->get_candidates()) eq '';
say $cl->get_solution() == 5;
say not $cl->solvable();

$cl = CellMemory->rehash($c->hash());
say ref $cl eq 'CellMemory';
say $cl ne $c;
say scalar($cl->get_candidates ) eq '13456789';
say $cl->solve(2) eq 0;
say join( '', $cl->get_candidates()) eq '13456789';
say scalar $c->get_candidates('bits') eq '101111111';


say join( '', $c->restate([0,0,0,3,4,0,0,0,0,0])) eq '0003400000';
say join( '', $c->get_candidates()) eq '34';
say scalar $c->get_candidates('bits') eq '001100000';
say $c->remove_candidate(3) > 0;
say $c->solvable();
say not $c->get_solution();
say $c->has_candidate(4) > 0;
say $c->solve == 4;
say $c->get_solution == 4;
say $c->has_digit(4) > 0;
say not $c->has_digit(3);
say $c->hash == 4;
say not $c->solvable;
say not $c->has_candidate(4);
say not $c->get_candidates;
say join( '',@{$c->state}) eq '4000000000';
say (scalar $c->get_candidates('bits') eq '000000000');
say (join( '', $c->get_candidates('bits')) eq '000000000');
$cl = CellMemory->rehash($c->hash());
say $cl->get_solution == 4;

$c = CellMemory->new();
say $c->solve(1) ~~ [2,3,4,5,6,7,8,9];
#say '..';

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';

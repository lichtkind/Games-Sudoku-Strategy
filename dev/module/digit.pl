use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use Benchmark;
use GroupDigitMemory;

my $t = Benchmark->new;
my $c = GroupDigitMemory->new();
say ref $c eq 'GroupDigitMemory';
say $c->candidate_count() == 9;
say join( '', $c->get_candidates()) eq '123456789';
say join( '', $c->get_candidates('bits')) eq '111111111';
say scalar $c->get_candidates() eq '123456789';
say scalar $c->get_candidates('bits') eq '111111111';
say not $c->has_candidate(10);
say not $c->has_candidate(0);
say $c->has_candidate(2) > 0;
say $c->remove_candidate(2) > 0;
say scalar( $c->get_candidates ) eq '13456789';
say $c->candidate_count() == 8;
say not $c->has_candidate(2) == 2;
say $c->remove_candidate(2) == 0;
say $c->add_candidate(2) == 2;
say $c->candidate_count() == 9;
say $c->has_candidate(2) == 2;
say $c->remove_candidate(2) == 2;
say $c->set_solution(1) == 1;
say $c->get_solution() == 1;
say $c->candidate_count() == 7;

my $cl = $c->clone();
say ref $cl eq 'GroupDigitMemory';
say $cl ne $c;
say scalar($cl->get_candidates ) eq '3456789';
say $cl->candidate_count() == 7;
say $cl->get_solution() eq 1;
say $cl->unsolve() eq 1;
say scalar($cl->get_candidates ) eq '13456789';
say $cl->candidate_count() == 8;

say join( '', $c->restate([0,0,0,3,4,0,0,0,0,0])) eq '0003400000';
say join( '', $c->get_candidates()) eq '34';
say $c->remove_candidate(3) == 3;
say $c->get_solution() == 0;
say $c->has_candidate(4) == 4;
say $c->remove_candidate(4) == 4;
say not $c->has_candidate(4);
say not $c->get_candidates;
say join( '',@{$c->state}) eq '0000000000';
say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';


1;

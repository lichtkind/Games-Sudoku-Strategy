use v5.18;
use warnings;
use Benchmark;


package Converter;

my (%count_bits, %b2c, %c2b);

for my $nr (0..511){
    my $bit_str = sprintf "%09b", $nr;
    my @bits = reverse split '', $bit_str;
    $count_bits{$bit_str} = int grep {$_} @bits;
    my @cand = grep {$_} map {$bits[$_-1] ? $_ : 0} 1..9;
    my $cand = join '', @cand;
    $b2c{$bit_str} = [$cand, @cand];
    $c2b{$cand} = $bit_str;
}

sub count_bits         { $count_bits{$_[0]} }
sub bits_to_candidates { $b2c{$_[0]}        }
sub candidates_to_bits { $c2b{$_[0]}        }

package main;

my $t = Benchmark->new;

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';



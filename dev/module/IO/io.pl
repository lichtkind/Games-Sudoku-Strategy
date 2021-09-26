use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';
use utf8;
use open (IN => ':encoding(utf-8)', OUT => ':utf8');
use warnings FATAL => 'utf8';
use Benchmark;
use IO;

my $t = Benchmark->new;

my $in_file = 'aai.sdk.txt';
my $out_file = 'aao.sdk.txt';
my $msg_aa = IO::load_puzzle( $in_file );
IO::save_puzzle($out_file, $msg_aa);
my $msg_aa_re = IO::load_puzzle( $out_file );
say $msg_aa->command_hash eq $msg_aa_re->command_hash;
say $msg_aa->trigger_hash eq $msg_aa_re->trigger_hash;
#say "@$_" for $msg1->commands;

my $in_file2 = 'cai.sdk.txt';
my $out_file2 = 'cao.sdk.txt';
my $msg_ca = IO::load_puzzle( $in_file2 );
say $msg_aa->command_hash eq $msg_ca->command_hash;
say $msg_aa->trigger_hash eq $msg_ca->trigger_hash;
IO::save_puzzle($out_file2, $msg_aa);
my $msg_ca_re = IO::load_puzzle( $out_file2 );
say $msg_ca->command_hash eq $msg_ca_re->command_hash;
say $msg_ca->trigger_hash eq $msg_ca_re->trigger_hash;

say "    computed in ", sprintf("%.4f",timediff( Benchmark->new, $t)->[1]), ' sec';

my $msg_file = 'msg.txt';
open (my $FH, ">", $msg_file ) or die "Could not open file '$msg_file': $!";
say $FH $msg_aa->hash;
say $FH $msg_aa_re->hash;
say $FH $msg_ca->hash;
say $FH $msg_ca_re->hash;


#say "@$_" for $msg2->commands;

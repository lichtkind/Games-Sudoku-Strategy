use v5.18;
use warnings;
use lib '.';
use open (IN => ':encoding(utf-8)', OUT => ':utf8');
use Message;

package IO;

sub load { # whatever *
    my ($file) = @_;
    open (my $FH, "<", $file ) or die "Could not open file '$file': $!";
    my $str = do { local $/; <$FH> };
}

sub save {
    my ($file) = @_;
    open ( my $FH, '>', $file ) or die "Could not open file '$file': $!";
    #print $FH $bytes;
    #close $FH;

}

sub load_puzzle { # rätsel
    my ($file) = @_;
    my ($grid, $cmd) = ([], []);
    open (my $FH, "<", $file ) or die "Could not open file '$file': $!";
    while (<$FH>){
        tr/|_//d;
        if (/\./){tr/\./0/}
        else     {tr/  /0/}
        s/\D//g;
        next if length ($_) < 9;
        push @$grid, [ split '', substr $_, 0, 9 ];
    }
    return unless @$grid == 9;
    for my $r (1..9) {
        for my $c (1..9) {
            my $d = $grid->[$r-1][$c-1];
            push @$cmd, [$r, $c, $d] if $d;
        }
    }
#say "@$_" for @$cmd;
#say '--';
    Message->new($cmd, [], "loaded from $file",['i', 'file']);
}

sub save_puzzle {
    my ($file, $msg) = @_;
    my $grid = [map {[('.') x 9]} 1..9];
    for my $cmd ($msg->commands){
        $grid->[$cmd->[0]-1][$cmd->[1]-1] = $cmd->[2] if $cmd->[2] > 0;
    }
    my $bar = '-' x 22;
    open (my $FH, ">", $file ) or die "Could not open file '$file': $!";
    for my $row (1..9){
        for my $col (1..9){
            print $FH ' '.$grid->[$row-1][$col-1];
            print $FH ' '.'|' if $col == 3 or $col == 6;
        }
        say $FH '';
        say $FH $bar if $row == 3 or $row == 6;
    }
}

sub load_game { # spielstand
    my ($file) = @_;
    my $log = [];
    $log;
}

sub save_game {
    my ($file, $log) = @_;
}

sub load_evaluation { # spielstand
    my ($file) = @_;
}

sub save_evaluation {
    my ($file) = @_;
}

1;

use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use utf8;
use lib '.';

package Message;

sub new {
    my ($pkg, $cmd, $trigger, $reason, $category) = @_;
    return unless ref $cmd eq 'ARRAY' and ref $trigger eq 'ARRAY'and ref $category eq 'ARRAY' and ref $reason ne 'ARRAY';
    $cmd     = [$cmd] if ref $cmd->[0] ne 'ARRAY';
    $trigger = [$trigger] if ref $trigger->[0] ne 'ARRAY';
    bless _compile([ _sort([ grep {_is_cmd($_)} map {_expand_cell_ref($_)} @$cmd ]),
                     _sort([ grep {_is_cmd($_)} map {_expand_cell_ref($_)} @$trigger, ]),  $reason,  [@$category] ]);
}
sub state   { my $state = _deep_clone( $_[0] ); splice @$state, 4; $state }
sub restate { bless _compile( _deep_clone( $_[1] ) ) }
sub clone   { __PACKAGE__->restate( $_[0]->state() ) }

########################################################################
sub hash   { $_[0][6] }
sub rehash {
    my ($pkg, $hash) = @_;
    my @part = split ';', $hash;
    my $cmd     = _sort([ map {[split '\.', $_]} split ':', $part[0] ]);
    my $trigger = _sort([ map {[split '\.', $_]} split ':', $part[1] ]);
    bless _compile([ $cmd, $trigger, $part[2], [split ':', $part[3]] ]);
}
########################################################################
sub _deep_clone {
    my $original = shift;
    my $clone = [ @$original ];
    $clone->[$_] = [ @{$clone->[$_]} ] for 0,1,3;
    @{$clone->[0]} = map {[@$_]}  @{$clone->[0]};
    @{$clone->[1]} = map {[@$_]}  @{$clone->[1]};
    $clone;
}

sub _sort {
    my ($list) = @_;
    return $list if ref $list ne 'ARRAY' or @$list == 0 or ref $list->[0] ne 'ARRAY' or @{$list->[0]} != 3;
    my @sol = grep {$_->[2] >= 0} @$list;
    my @cand = grep {$_->[2] < 0} @$list;
    @sol = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]  } @sol;
    @cand = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $b->[2] <=> $a->[2] } @cand;
    @$list = (@sol, @cand);
    for my $i (reverse 1 .. $#$list){ # del dups
        splice @$list, $i, 1 if $list->[$i][0] == $list->[$i-1][0]
                            and $list->[$i][1] == $list->[$i-1][1]
                            and $list->[$i][2] == $list->[$i-1][2];
    }
    $list;
}
sub _compile {
    my ($self) = @_;
    $self->[4] = join ':', map { join '.', @$_ } @{$self->[0]};
    $self->[5] = join ':', map { join '.', @$_ } @{$self->[1]};
    $self->[6] = join ';', $self->[4], $self->[5], $self->[2], join(':', @{$self->[3]});
    $self;
}

########################################################################
sub _koor            { ($_[0]->{'row'}{'nr'}, $_->[0]->{'col'}{'nr'}) }
sub _expand_cell_ref { (@{$_[0]} == 2 and ref $_[0][0] eq 'HASH') ? [_koor($_[0][0]), $_[0][1]] : $_[0] }

sub _is_cmd          { ref $_[0] eq 'ARRAY' and @{$_[0]} == 3 and $_[0][0] =~ /^\d$/ and $_[0][1] =~ /^\d$/ and $_[0][2] =~ /^-?\d$/ }
sub add_commands {
    my $self = shift;
    for my $cmd (@_){
        $cmd = _expand_cell_ref($cmd);
        next unless _is_cmd( $cmd );
        push @{$self->[0]}, $cmd;
    }
    _sort($self->[0]);
    _compile($self);
    $self->[0];
}
sub remove_commands {
    my $self = shift;
    for my $cmd (@_){
        $cmd = _expand_cell_ref($cmd);
        next unless _is_cmd( $cmd );
        @{$self->[0]} = grep {$_->[0] != $cmd->[0] or $_->[1] != $cmd->[1] or $_->[2] != $cmd->[2]} @{$self->[0]};
    }
    _compile($self);
    $self->[0];
}
########################################################################

sub has_solution    { $_[0][0][0][2] > 0 }
sub commands        { @{$_[0][0]} }
sub trigger         { @{$_[0][1]} }
sub reason          { $_[0][2]    }
sub category        { $_[0][3][0] }
sub sub_category    { $_[0][3][1] if exists $_[0][3][1]}
sub sub_sub_category{ $_[0][3][2] if exists $_[0][3][2]}
sub command_hash    { $_[0][4] }
sub trigger_hash    { $_[0][5] }
sub key             { $_[0][6] }

1;

__END__

@msg:

0:  @actions [row, col, +- digit (+ solution - candidate)]
1:  @trigger [row, col]
2:  ~reason
3:  @category
4:  ~cmd_hash
5:  ~trigger_hash
6:  ~full_hash (key)
.:;


i                      init
cs                     cell solution
gs   type              group solution  (last candidate in group)
gb   type  d/p  size   group block of digits/positions
gi   v/h               group inter section (last of three)
co                     chain overlay
g                      geometry    mephistomel ring
f                      fork

 [$_->{'row'}{'nr'}, $_->{'col'}{'nr'}, -$digit, $self->{'name'}, ['gis']]

# gc   type              group candidate

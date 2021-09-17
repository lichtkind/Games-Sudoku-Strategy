use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';


package StateGraph;

my @hash_key = qw/grid_state in out open_node/;
my @scalar_key = qw/max_ID current_ID/;

########################################################################

sub new {
    my ($pkg) = @_;
    bless { grid_state => { 0 => '0' x 81}, ID => {'0' x 81 => 0}, in => {0 =>[]}, out => {0 =>[]},
            current_ID => 0, max_ID => 0, d => {0 => 0}, open_out => {} };
}
sub state   { 
    my ($self) = @_;
    my $state = {};
    $state->{$_} = $self->{$_} for @scalar_key;
    for my $key (@hash_key){
        $state->{$key} = { %{$self->{$key}{$_}} } for keys %{$state->{$key}};
    }
    $state->{$_} = {%{$self->{$_}}} for @hash_key;
    $state;
}
sub restate {
    my ($pkg, $state) = @_;
    my $self = {};
    $self->{$_} = $state->{$_} for @scalar_key;
    for my $key (@hash_key){
        $self->{$key} = { %{$state->{$key}{$_}} } for keys %{$state->{$key}};
    }
    $self->{'ID'}{$state->{'grid_state'}{$_}} = $_ for keys %{$state->{'grid_state'}}; # gen backref
    bless $self;
}
sub clone           { __PACKAGE__->restate( $_[0]->state() ) }
########################################################################

sub get_state          { $_[0]->{'grid_state'}{$_[1]} }
sub get_state_ID       { $_[0]->{'ID'}{$_[1]} }
sub get_current_state  { $_[0]->{'current_ID'} }
sub set_current_state  {
    my ($self, $stateID) = @_;
    $self->{'current_ID'} = $stateID if exists $self->{'grid_state'}{$stateID};
}

sub add_state  {
    my ($self, $msg_hash, $grid_state, $progress) = @_;
    return unless defined $msg_hash and defined $grid_state and length($grid_state) == 81;
    my $old_ID = $self->{'current_ID'};
    return if $old_ID > 0 and not exists $self->{'open_out'}{$old_ID}{$msg_hash};  # keine vorbereitete kante
    return if exists $self->{'out'}{$old_ID}{$msg_hash};                           # kante schon gezogen
    my $new_ID;
    if (exists $self->{'ID'}{$grid_state} ){
        $new_ID = $self->{'ID'}{$grid_state}
    } else {
        $new_ID = ++$self->{'max_ID'};
        return if ref $progress ne 'ARRAY';
        $self->{'open_out'}{$new_ID}{$_}-- for @$progress;        
        $self->{'grid_state'}{$new_ID} = $grid_state;
        $self->{'ID'}{$grid_state} = $new_ID;
    }
    if ($old_ID){
        delete $self->{'open_out'}{$old_ID}{$msg_hash};
        delete $self->{'open_out'}{$old_ID} unless %{$self->{'open_out'}{$old_ID}};
    }
    $self->{'out'}{$old_ID}{$msg_hash} = $new_ID;
    $self->{'in'}{$new_ID}{$msg_hash} = $old_ID;
    $self->{'current_ID'} = $new_ID;
}

########################################################################

sub add_edge  {
    my ($self, $grid_state, $msg_hash) = @_;
    return unless defined $msg_hash and $msg_hash and exists $self->{'grid_state'}{$grid_state} 
           and not exists $self->{'out'}{$grid_state}{$msg_hash};
    $self->{'open_out'}{$grid_state}{$msg_hash}--;
}

sub has_open_edges { keys %{$_[0]->{'open_out'}} > 0 ? 1 : 0 }
sub get_open_edges {
    my ($self) = @_;
    my @open;
    for my $state_ID (keys %{$self->{'open_out'}}){
        for my $msg_ID (keys %{$self->{'open_out'}{$state_ID}}){
            push @open, [$self->{'grid_state'}{$state_ID}, $msg_ID];
        }
    }
    @open;
}


1;

__END__

edges: in out msg_ID => vID
vertex: ID => grid state

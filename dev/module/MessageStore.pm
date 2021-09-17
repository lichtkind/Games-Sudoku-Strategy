use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';

use Message;

package MessageStore;

sub new   {  my ($pkg) = @_;   bless { store => {},  };   }
sub state {  my ($self) = @_; { map { $_ => $self->{'store'}{$_}->state } keys %{$self->{'store'}} }  }
sub restate {
    my ($pkg, $state) = @_;
    my $self = __PACKAGE__->new();
    $self->{'store'}{$_} = Message->restate( $state->{$_} ) for keys %$state;
    $self;
}
sub clone { __PACKAGE__->restate( $_[0]->state() ) }

sub hash {
    my ($self) = @_;
    join ';', $self->hash, $self->[2],  join(':', @{$self->[3]});
}
sub rehash {
    my ($pkg, $hash) = @_;
    my @part = split ';', $hash;
    my $cmd   = _sort([map {[split '.', $_]} split ':', $part[0]]);
    my $trigger = _sort([map {[split '.', $_]} split ':', $part[1]]);
    bless [ $cmd, $trigger, $part[2], [split ':', $part[3]] ];
}
########################################################################
sub elements { values %{$_[0]->{'store'}} }
sub keys     { keys   %{$_[0]->{'store'}} }
########################################################################

sub get_msg {
    my ($self, $msgID) = @_;
    $msgID = $msgID->hash if ref $msgID eq 'Message';
    $self->{'store'}{$msgID};
}

sub add_msg {
    my ($self, $msg) = @_;
    return unless ref $msg eq 'Message' and not exists $self->{'store'}{$msg->hash};
    $self->{'store'}{$msg->hash} = $msg;
}

sub derive_msg  {
    my ($self, $msgID, @cmd) = @_;
    my $msg = $self->{'store'}{$msgID};
    return unless defined $msg;
    $msg = $msg->clone;
    $msg->remove_commands( @cmd );
    $self->add_msg( $msg );
}



1;

__END__

ID => { msg int => ID }

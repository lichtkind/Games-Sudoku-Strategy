use v5.18;
use warnings;
no warnings 'experimental::smartmatch';
use lib '.';

use Message;

package MessageQ;

sub new {
    my ($pkg) = @_;
    bless { q => [], nextq => []};
}
sub state {
    my ($self) = @_;
    my $state = [[],[]];
    @{$state->[0]} = map {$_->hash} @{$self->{'q'}};
    @{$state->[1]} = map {$_->hash} @{$self->{'nextq'}};
    $state;
}
sub restate {
    my ($pkg, $state) = @_;
    my $self = __PACKAGE__->new();
    @{$self->{'q'}}     = map {Message->rehash($_)} @{$state->[0]};
    @{$self->{'nextq'}} = map {Message->rehash($_)} @{$state->[1]};;
    $self;
}
sub clone    { __PACKAGE__->restate( $_[0]->state() ) }

########################################################################
sub elements     { @{$_[0]->{'q'}} }
sub last_element  { $_[0]->{'q'}[-1] }
sub future_elemets { @{$_[0]->{'nextq'}} }
########################################################################

sub add {
    my ($self, @msg) = @_;
    @msg = grep {ref $_ eq 'Message'} @msg;
    return unless @msg;
    $self->{'nextq'} = [];
    push @{$self->{'q'}}, @msg;
}


sub can_undo { (int @{$_[0]->{'q'}}) and ($_[0]->{'q'}[-1]->reason()) ? 1 : 0 }
sub can_redo { (int @{$_[0]->{'nextq'}}) ? 1 : 0 }
sub undo {
    my ($self) = @_;
    return unless $self->can_undo();
    push @{$self->{'nextq'}}, (pop @{$self->{'q'}});

}

sub redo {
    my ($self) = @_;
    return unless $self->can_redo();
    push @{$self->{'q'}}, pop @{$self->{'nextq'}};
}


1;

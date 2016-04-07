package Stacker;

use strict;
use warnings;

use TestHelpers;

use base 'Collector';

sub _stack
{
    my $self = shift;

    if (@_)
    {
        $self->{_stack} = shift;
    }

    return $self->{_stack};
}

sub _push
{
    my $self = shift;
    my $item = shift;

    push @{$self->_stack()}, $item;

    return;
}

sub _reset
{
    my $self = shift;

    $self->_stack([]);

    return;
}

sub _calc_op_callback {
    my $self = shift;

    return sub {
        my $item = shift;

        return $self->_push($item);
    };
}

sub test
{
    my ($self, $value, $blurb) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    eq_or_diff ($self->_stack(), $value, $blurb);

    $self->_reset;

    return;
}

1;

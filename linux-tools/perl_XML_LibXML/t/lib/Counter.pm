package Counter;

use strict;
use warnings;

use base 'Collector';

sub _counter
{
    my $self = shift;

    if (@_)
    {
        $self->{_counter} = shift;
    }

    return $self->{_counter};
}


sub _increment
{
    my $self = shift;

    $self->_counter($self->_counter + 1);

    return;
}

sub _reset
{
    my $self = shift;

    $self->_counter(0);

    return;
}

sub _calc_op_callback {
    my $self = shift;

    return sub {
        return $self->_increment();
    };
}

sub test
{
    my ($self, $value, $blurb) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Test::More::is ($self->_counter(), $value, $blurb);

    $self->_reset;

    return;
}

1;

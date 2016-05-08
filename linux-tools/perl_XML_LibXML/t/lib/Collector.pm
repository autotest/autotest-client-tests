package Collector;

use strict;
use warnings;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->_reset;

    $self->_callback( $args->{gen_cb}->($self->_calc_op_callback()) );

    $self->_init_returned_cb;

    return;
}

sub _callback
{
    my $self = shift;

    if (@_)
    {
        $self->{_callback} = shift;
    }

    return $self->{_callback};
}

sub _returned_cb
{
    my $self = shift;

    if (@_)
    {
        $self->{_returned_cb} = shift;
    }

    return $self->{_returned_cb};
}

sub _init_returned_cb
{
    my $self = shift;

    $self->_returned_cb(
        sub {
            return $self->_callback()->(@_);
        }
    );

    return;
}

sub cb
{
    return shift->_returned_cb();
}

1;

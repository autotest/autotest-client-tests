#!/usr/bin/perl

use strict;
BEGIN { $^W = 1 }

use Test::More;

use Sub::Uplevel;

plan tests => 3;

sub get_caller {
    return caller(shift);
}

sub wrapper {
    my $height = shift;
    return uplevel 1, \&get_caller, $height;
}

{
  my @caller = wrapper(0);
  ok(scalar @caller, "caller(N) in stack returns list");
}

{
  my @caller = wrapper(1);
  is(scalar @caller, 0, "caller(N) out of stack returns empty list");
}

{
  my @caller = caller;
  is(scalar @caller, 0, "caller from main returns empty list");
}

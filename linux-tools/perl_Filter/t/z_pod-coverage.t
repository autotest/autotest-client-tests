# -*- perl -*-
use strict;
use warnings;
use Test::More;

plan skip_all => 'done_testing requires 5.8.6' if $] <= 5.008005;
plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{IS_MAINTAINER};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

all_pod_coverage_ok();

done_testing();

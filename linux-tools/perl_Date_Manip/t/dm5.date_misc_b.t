#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Date (Internal=2)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
Date_Init("Internal=2");

$tests="
# Tests YYMMDD time

1996061800:00:00 => '1996-06-18 00:00:00'

# Tests YYMMDDHHMNSS

19960618000000   => '1996-06-18 00:00:00'
";

$t->tests(func  => \&ParseDate,
          tests => $tests);
$t->done_testing();

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (delta,delta,exact)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");

$tests="

1:1:1:1 2:2:2:2 0 => +0:0:0:3:3:3:3

1:1:1:1 2:-1:1:1 0 => +0:0:0:3:0:0:0

1:1:1:1 0:-11:5:6 0 => +0:0:0:0:13:55:55

1:1:1:1 0:-25:5:6 0 => -0:0:0:0:0:4:5

1:1:0:1:1:1:1 2:12:1:2:48:120:120 0 => +4:1:1:5:3:3:1

1:1:0:1:1:1:1 2:12:0:-2:48:120:120 0 => +4:1:-0:3:1:0:59

";

$t->tests(func  => \&DateCalc,
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

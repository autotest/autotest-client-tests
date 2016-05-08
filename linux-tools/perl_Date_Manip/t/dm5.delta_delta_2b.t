#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (delta,delta,business 8:30-5:00)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");

$tests="

+1:6:30:30 +1:3:45:45 2 => +0:0:0:3:1:46:15

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

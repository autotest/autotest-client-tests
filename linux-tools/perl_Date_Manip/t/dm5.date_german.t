#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Date (German)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
Date_Init("ForceDate=1997-03-08-12:30:00");
Date_Init("Language=German","DateFormat=US","Internal=0");

$tests="

08.04.1999 => 1999080400:00:00

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

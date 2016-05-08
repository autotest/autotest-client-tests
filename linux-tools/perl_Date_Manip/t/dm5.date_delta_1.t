#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,delta,approx)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
$tests="
'Wed Feb 7 1996 8:00' +1:1:1:1 1 => 1996020809:01:01

'Wed Nov 20 1996 noon' +0:5:0:0 1 => 1996112017:00:00

'Wed Nov 20 1996 noon' +0:13:0:0 1 => 1996112101:00:00

'Wed Nov 20 1996 noon' +3:2:0:0 1 => 1996112314:00:00

'Wed Nov 20 1996 noon' -3:2:0:0 1 => 1996111710:00:00

'Wed Nov 20 1996 noon' +3:13:0:0 1 => 1996112401:00:00

'Wed Nov 20 1996 noon' +6:2:0:0 1 => 1996112614:00:00

'Dec 31 1996 noon' +1:2:0:0 1 => 1997010114:00:00

'Jan 31 1997 23:59:59' '+ 1 sec' 1 => 1997020100:00:00

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

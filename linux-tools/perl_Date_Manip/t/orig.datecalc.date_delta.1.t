#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,delta,business 8:30-5:00)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
   my($d1,$d2) = (@_);
   DateCalc($d1,$d2);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=$testdir/Manip.cnf");
Date_Init("WorkDayBeg=08:30","WorkDayEnd=17:00");

$tests="

'Wed Nov 20 1996 noon' '+0:5:0:0 business' => 1996112108:30:00

'Wed Nov 20 1996 noon' '+3:7:0:0 business' => 1996112610:30:00

'Mar 31 1997 16:59:59' '+ 1 sec business'  => 1997040108:30:00

";

$t->tests(func  => \&test,
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

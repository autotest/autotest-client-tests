#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Date_IsHoliday';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  my($type,$date) = @_;
  if ($type eq 'scalar') {
     $ret = Date_IsHoliday($date);
     return $ret;
  } else {
     @ret = Date_IsHoliday($date);
     return @ret;
  }
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=$testdir/Holidays.3.cnf");

$tests ="

scalar 2010-01-01 =>
   'New Years Day (observed)'

list   2010-01-01 =>
   'New Years Day (observed)'
   'New Years Day'

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

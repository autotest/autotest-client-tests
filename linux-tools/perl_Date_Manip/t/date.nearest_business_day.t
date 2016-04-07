#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'nearest_business_day';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($date,@test)=@_;
  $obj->parse($date);
  $obj->nearest_business_day(@test);
  $ret = $obj->value();
  return $ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

$tests="

#       July 2007
# Su Mo Tu We Th Fr Sa
#  1  2  3  4  5  6  7
#  8  9 10 11 12 13 14
# 15 16 17 18 19 20 21
# 22 23 24 25 26 27 28
# 29 30 31

'Jul 18 2007 12:00:00' => 2007071812:00:00

'Jul 21 2007 12:00:00' => 2007072012:00:00

'Jul 22 2007 12:00:00' => 2007072312:00:00


'Jul 4 2007 12:00:00' => 2007070412:00:00

'Jul 4 2007 12:00:00' 1 => 2007070412:00:00

'Jul 4 2007 12:00:00' 0 => 2007070412:00:00

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

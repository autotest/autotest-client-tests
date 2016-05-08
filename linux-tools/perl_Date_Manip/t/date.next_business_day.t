#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'next_business_day';
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
  $obj->next_business_day(@test);
  $ret = $obj->value();
  return $ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

$tests="

#      August 2009
# Su Mo Tu We Th Fr Sa
#                    1
#  2  3  4  5  6  7  8
#  9 10 11 12 13 14 15
# 16 17 18 19 20 21 22
# 23 24 25 26 27 28 29
# 30 31

#### Day 0, no timecheck

'Aug 18 2009 12:00:00' 0 0 => 2009081812:00:00

'Aug 18 2009 05:00:00' 0 0 => 2009081805:00:00

'Aug 16 2009 12:00:00' 0 0 => 2009081712:00:00


#### Day 0, timecheck

'Aug 18 2009 12:00:00' 0 1 => 2009081812:00:00

'Aug 18 2009 05:00:00' 0 1 => 2009081808:00:00

'Aug 16 2009 12:00:00' 0 1 => 2009081708:00:00


#### Day 2, no timecheck

'Aug 18 2009 12:00:00' 2 0 => 2009082012:00:00

'Aug 18 2009 05:00:00' 2 0 => 2009082005:00:00

'Aug 16 2009 12:00:00' 2 0 => 2009081912:00:00


#### Day 2, timecheck

'Aug 18 2009 12:00:00' 2 1 => 2009082012:00:00

'Aug 18 2009 05:00:00' 2 1 => 2009082008:00:00

'Aug 16 2009 12:00:00' 2 1 => 2009081908:00:00


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

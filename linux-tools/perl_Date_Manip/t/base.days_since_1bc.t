#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'days_since_1BC';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->days_since_1BC(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ 1 1 1 ]      => 1

[ 2 1 1 ]      => 366

[ 1997 12 10 ] => 729368

[ 1998 12 10 ] => 729733


729368 => [ 1997 12 10 ]

729733 => [ 1998 12 10 ]

1      => [ 1 1 1 ]

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

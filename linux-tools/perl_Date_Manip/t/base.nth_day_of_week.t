#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'nth_day_of_week';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->nth_day_of_week(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

1999 1 5    => [ 1999 1 1 ]

1999 7 7    => [ 1999 2 14 ]

1999 -1 6 1 => [ 1999 1 30 ]

1999 -2 6 1 => [ 1999 1 23 ]

1999 3 6 12 => [ 1999 12 18 ]

2029 -1 7 3 => [ 2029 3 25 ]

2029 -3 7 3 => [ 2029 3 11 ]

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

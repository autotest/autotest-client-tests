#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'day_of_year (Y/M/D)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->day_of_year(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ 1999 1 1 ]  => 1

[ 1999 1 21 ] => 21

[ 1999 3 1 ]  => 60

[ 2000 3 1 ]  => 61

[ 1980 2 29 ] => 60

[ 1980 3 1 ]  => 61


1999 1  => [ 1999 1 1 ]

1999 21 => [ 1999 1 21 ]

1999 60 => [ 1999 3 1 ]

2000 61 => [ 2000 3 1 ]

1980 60 => [ 1980 2 29 ]

1980 61 => [ 1980 3 1 ]

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

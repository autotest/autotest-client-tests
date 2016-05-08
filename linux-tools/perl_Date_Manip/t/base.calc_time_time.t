#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc_time_time';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->calc_time_time(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ +2 2 2 ]   [ +1 1 1 ]     => [ 3 3 3 ]

[ +2 2 2 ]   [ -1 -1 -1 ]   => [ 1 1 1 ]

[ +2 2 2 ]   [ 1 1 1 ] 1    => [ 1 1 1 ]

[ 10 45 90 ] [ 5 30 45 ]    => [ 16 17 15 ]

[ 10 45 90 ] [ -5 -30 -15 ] => [ 5 16 15 ]

[ 5 -5 +5 ]  [ -2 +2 -2 ]   => [ 2 57 3 ]

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

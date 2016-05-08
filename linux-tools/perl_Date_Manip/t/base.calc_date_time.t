#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc_date_time';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->calc_date_time(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ 2000 01 15 12 00 00 ] [ 1 0 0 ]    => [ 2000 1 15 13 0 0 ]

[ 2000 01 15 12 00 00 ] [ -1 0 0 ]   => [ 2000 1 15 11 0 0 ]

[ 2000 01 15 12 00 00 ] [ 1 1 0 ]    => [ 2000 1 15 13 1 0 ]

[ 2000 01 15 12 00 00 ] [ -1 -1 0 ]  => [ 2000 1 15 10 59 0 ]

[ 2000 01 15 12 00 00 ] [ 1 1 1 ]    => [ 2000 1 15 13 1 1 ]

[ 2000 01 15 12 00 00 ] [ -1 -1 -1 ] => [ 2000 1 15 10 58 59 ]

[ 2000 01 15 12 00 00 ] [ 0 1 0 ]    => [ 2000 1 15 12 1 0 ]

[ 2000 01 15 12 00 00 ] [ 0 -1 0 ]   => [ 2000 1 15 11 59 0 ]

[ 2000 01 15 12 00 00 ] [ 0 1 1 ]    => [ 2000 1 15 12 1 1 ]

[ 2000 01 15 12 00 00 ] [ 0 -1 -1 ]  => [ 2000 1 15 11 58 59 ]

[ 2000 01 15 12 00 00 ] [ 0 0 1 ]    => [ 2000 1 15 12 0 1 ]

[ 2000 01 15 12 00 00 ] [ 0 0 -1 ]   => [ 2000 1 15 11 59 59 ]

[ 2000 01 15 12 00 00 ] [ +24 0 0 ]  => [ 2000 1 16 12 0 0 ]

[ 2000 01 15 12 00 00 ] [ -24 0 0 ]  => [ 2000 1 14 12 0 0 ]

[ 1999 12 31 12 00 00 ] [ +24 0 0 ]  => [ 2000 1 1 12 0 0 ]

[ 2000 01 01 12 00 00 ] [ -24 0 0 ]  => [ 1999 12 31 12 0 0 ]

[ 2000 12 31 12 00 00 ] [ +24 0 0 ]  => [ 2001 1 1 12 0 0 ]

[ 2000 01 15 12 00 00 ] [ +49 1 0 ]  => [ 2000 1 17 13 1 0 ]

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

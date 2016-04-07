#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc_date_date';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->calc_date_date(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ 2007 01 15 10 00 00 ] [ 2007 01 15 12 00 00 ] => [ 2 0 0 ]

[ 2007 01 15 12 00 00 ] [ 2007 01 15 10 00 00 ] => [ -2 0 0 ]

[ 2007 01 15 10 30 00 ] [ 2007 01 15 12 15 00 ] => [ 1 45 0 ]

[ 2007 01 15 12 15 00 ] [ 2007 01 15 10 30 00 ] => [ -1 -45 0 ]

[ 2007 01 31 10 00 00 ] [ 2007 02 01 12 00 00 ] => [ 26 0 0 ]

[ 2007 02 01 12 00 00 ] [ 2007 01 31 10 00 00 ] => [ -26 0 0 ]

[ 2007 12 31 10 00 00 ] [ 2008 01 01 12 00 00 ] => [ 26 0 0 ]

[ 2008 01 01 12 00 00 ] [ 2007 12 31 10 00 00 ] => [ -26 0 0 ]

[ 2007 01 15 10 00 00 ] [ 2007 01 17 12 00 00 ] => [ 50 0 0 ]

[ 2007 01 17 12 00 00 ] [ 2007 01 15 10 00 00 ] => [ -50 0 0 ]

[ 2007 01 15 10 30 00 ] [ 2007 01 17 12 15 00 ] => [ 49 45 0 ]

[ 2007 01 17 12 15 00 ] [ 2007 01 15 10 30 00 ] => [ -49 -45 0 ]

[ 2007 01 30 10 00 00 ] [ 2007 02 02 12 00 00 ] => [ 74 0 0 ]

[ 2007 02 02 12 00 00 ] [ 2007 01 30 10 00 00 ] => [ -74 0 0 ]

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

1;

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc_date_delta';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->calc_date_delta(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

[ 2009 08 15 12 00 00 ] [ 0 0 0 5 1 0 0 ] 0 => [ 2009 8 20 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 0 5 1 0 0 ] 1 => [ 2009 8 10 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 1 5 1 0 0 ] 0 => [ 2009 8 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 0 1 5 1 0 0 ] 1 => [ 2009 8 3 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 3 1 5 1 0 0 ] 0 => [ 2009 11 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 0 3 1 5 1 0 0 ] 1 => [ 2009 5 3 11 0 0 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 1 0 0 ] 0 => [ 2011 11 27 13 0 0 ]

[ 2009 08 15 12 00 00 ] [ 2 3 1 5 1 0 0 ] 1 => [ 2007 5 3 11 0 0 ]

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'date_period';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $per = $obj->date_period(@test);
  return ()  if (! $per);
  return @$per;
}

$obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

$tests="
[ 1 2 1 0 0 0 ] America/New_York 0 =>
   [ 1 1 2 0 0 0 ]
   [ 1 1 1 19 3 58 ]
   -04:56:02
   [ -4 -56 -2 ]
   LMT
   0
   [ 1883 11 18 16 59 59 ]
   [ 1883 11 18 12 3 57 ]
   0001010200:00:00
   0001010119:03:58
   1883111816:59:59
   1883111812:03:57

[ 1880 1 1 0 0 0 ] America/New_York 0 =>
   [ 1 1 2 0 0 0 ]
   [ 1 1 1 19 3 58 ]
   -04:56:02
   [ -4 -56 -2 ]
   LMT
   0
   [ 1883 11 18 16 59 59 ]
   [ 1883 11 18 12 3 57 ]
   0001010200:00:00
   0001010119:03:58
   1883111816:59:59
   1883111812:03:57

[ 1925 9 27 6 0 0 ] America/New_York 0 =>
   [ 1925 9 27 6 0 0 ]
   [ 1925 9 27 1 0 0 ]
   -05:00:00
   [ -5 0 0 ]
   EST
   0
   [ 1926 4 25 6 59 59 ]
   [ 1926 4 25 1 59 59 ]
   1925092706:00:00
   1925092701:00:00
   1926042506:59:59
   1926042501:59:59

[ 1925 9 27 1 0 0 ] America/New_York 1 0 =>
   [ 1925 9 27 6 0 0 ]
   [ 1925 9 27 1 0 0 ]
   -05:00:00
   [ -5 0 0 ]
   EST
   0
   [ 1926 4 25 6 59 59 ]
   [ 1926 4 25 1 59 59 ]
   1925092706:00:00
   1925092701:00:00
   1926042506:59:59
   1926042501:59:59

[ 1926 4 25 2 15 0 ] America/New_York 1 0 =>

[ 1926 4 25 3 15 0 ] America/New_York 1 0 =>
   [ 1926 4 25 7 0 0 ]
   [ 1926 4 25 3 0 0 ]
   -04:00:00
   [ -4 0 0 ]
   EDT
   1
   [ 1926 9 26 5 59 59 ]
   [ 1926 9 26 1 59 59 ]
   1926042507:00:00
   1926042503:00:00
   1926092605:59:59
   1926092601:59:59

[ 1926 9 26 1 15 0 ] America/New_York 1 0 =>
   [ 1926 9 26 6 0 0 ]
   [ 1926 9 26 1 0 0 ]
   -05:00:00
   [ -5 0 0 ]
   EST
   0
   [ 1927 4 24 6 59 59 ]
   [ 1927 4 24 1 59 59 ]
   1926092606:00:00
   1926092601:00:00
   1927042406:59:59
   1927042401:59:59

[ 1926 9 26 1 15 0 ] America/New_York 1 1 =>
   [ 1926 4 25 7 0 0 ]
   [ 1926 4 25 3 0 0 ]
   -04:00:00
   [ -4 0 0 ]
   EDT
   1
   [ 1926 9 26 5 59 59 ]
   [ 1926 9 26 1 59 59 ]
   1926042507:00:00
   1926042503:00:00
   1926092605:59:59
   1926092601:59:59

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

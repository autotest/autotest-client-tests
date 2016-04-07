#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'convert';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  return $obj->convert(@test);
}

$obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

$tests="

[ 1985 1 1 0 30 0 ] America/New_York America/Chicago =>
  0 [ 1984 12 31 23 30 0 ] [ -6 0 0 ] 0 CST

[ 1985 1 1 12 0 0 ] America/New_York America/Chicago =>
  0 [ 1985 1 1 11 0 0 ] [ -6 0 0 ] 0 CST

[ 1985 4 28 1 0 0 ] America/New_York America/Chicago =>
  0 [ 1985 4 28 0 0 0 ] [ -6 0 0 ] 0 CST

[ 1985 4 28 2 0 0 ] America/New_York America/Chicago => 4

[ 1985 4 28 2 30 0 ] America/New_York America/Chicago => 4

[ 1985 4 28 3 0 0 ] America/New_York America/Chicago =>
  0 [ 1985 4 28 1 0 0 ] [ -6 0 0 ] 0 CST

[ 1985 4 28 3 30 0 ] America/New_York America/Chicago =>
  0 [ 1985 4 28 1 30 0 ] [ -6 0 0 ] 0 CST

[ 1985 4 28 4 0 0 ] America/New_York America/Chicago =>
  0 [ 1985 4 28 3 0 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 0 30 0 ] America/New_York America/Chicago =>
  0 [ 1985 10 26 23 30 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 1 0 0 ] America/New_York America/Chicago 1 =>
  0 [ 1985 10 27 0 0 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 1 30 0 ] America/New_York America/Chicago 1 =>
  0 [ 1985 10 27 0 30 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 1 0 0 ] America/New_York America/Chicago 0 =>
  0 [ 1985 10 27 1 0 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 1 30 0 ] America/New_York America/Chicago 0 =>
  0 [ 1985 10 27 1 30 0 ] [ -5 0 0 ] 1 CDT

[ 1985 10 27 2 0 0 ] America/New_York America/Chicago =>
  0 [ 1985 10 27 1 0 0 ] [ -6 0 0 ] 0 CST

1985102702:00:00 America/New_York America/Chicago =>
  0 [ 1985 10 27 1 0 0 ] [ -6 0 0 ] 0 CST

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

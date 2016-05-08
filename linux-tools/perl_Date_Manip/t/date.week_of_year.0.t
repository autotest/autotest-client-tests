#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'week_of_year';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  my($date,$first) = @test;
  $obj->set("date",$date);
  return $obj->week_of_year($first);
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

$tests="

# Date, FirstDate

[ 2008 01 01 00 00 00 ] 7 => 1

[ 2008 01 06 00 00 00 ] 7 => 2

[ 2008 12 23 00 00 00 ] 7 => 52

[ 2008 12 28 00 00 00 ] 7 => 53

[ 2008 01 01 00 00 00 ] 1 => 1

[ 2008 01 06 00 00 00 ] 1 => 1

[ 2008 12 23 00 00 00 ] 1 => 52

[ 2008 12 28 00 00 00 ] 1 => 52

[ 2008 12 29 00 00 00 ] 1 => 53

[ 2005 01 01 00 00 00 ] 7 => 0

[ 2005 01 06 00 00 00 ] 7 => 1

[ 2005 12 23 00 00 00 ] 7 => 51

[ 2005 12 28 00 00 00 ] 7 => 52

[ 2005 01 01 00 00 00 ] 1 => 0

[ 2005 01 06 00 00 00 ] 1 => 1

[ 2005 12 23 00 00 00 ] 1 => 51

[ 2005 12 28 00 00 00 ] 1 => 52

[ 2005 12 29 00 00 00 ] 1 => 52

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

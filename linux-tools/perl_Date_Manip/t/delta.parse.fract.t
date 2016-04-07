#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (fractional)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $err = $obj->parse(@test);
  if ($err) {
     return $obj->err();
  } else {
     @val = $obj->value();
     return @val;
  }
}

$obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

$tests="

'1.5 days'                => 0 0 0 1 12 0 0

'1.1 years'               => 1 1 0 6 2 5 49

'1.1 years business'      => 1 1 0 4 3 7 59

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

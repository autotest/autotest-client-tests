#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'cmp';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $obj1->parse($test[0]);
  $obj2->parse($test[1]);
  return $obj1->cmp($obj2);
}

$obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj2 = $obj1->new_date();

$tests="

2007020312:00:00 2007020312:00:00 => 0

2007020312:00:00 2007020312:00:01 => -1

2007020312:00:01 2007020312:00:00 => 1

'2007020312:00:00 EST' '2007020312:00:00 CST' => -1

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

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

$obj1 = new Date::Manip::Delta;
$obj2 = $obj1->new_delta();

$tests="

0:0:0:0:-1:0:0   0:0:0:0:1:0:0   => -1

0:0:0:0:1:0:0    0:0:0:0:-1:0:0  => 1

0:0:0:0:1:0:0    0:0:0:0:0:60:0  => 0

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

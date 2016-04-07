#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (delta,delta,business 08:00-17:00)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;

  $err = $obj1->parse(shift(@test));
  if ($err) {
     return $obj1->err();
  }

  $err = $obj2->parse(shift(@test));
  if ($err) {
     return $obj2->err();
  }

  my $obj3 = $obj1->calc($obj2,@test);
  $ret = $obj3->value();
  return $ret;
}

$obj1 = new Date::Manip::Delta;
$obj1->config("forcedate","now,America/New_York");
$obj2 = $obj1->new_delta();

$tests="

'+1:6:30:30 business'  '+1:3:45:45 business'  => 0:0:0:2:10:16:15

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

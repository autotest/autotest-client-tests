#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (delta,delta,approx)';
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

1:1:1:1:1:1:1   2:12:5:2:48:120:120  => 4:1:6:3:51:3:1

1:1:1:1:1:1:1   2:12:-1:2:48:120:120 => 4:1:0:-1:49:0:59

2:3:4:5:6:7:8   1:2:3:4:5:6:7        => 3:5:8:2:11:13:15

2:3:4:5:6:7:8   1:2:3:4:5:6:7 1      => 1:1:1:1:1:1:1

1:1:0:1:1:1:1   2:12:1:2:48:120:120  => 4:1:1:3:51:3:1

1:1:0:1:1:1:1   2:12:0:-2:48:120:120 => 4:1:0:-1:49:0:59

2:3:4:5:6:7:8   1:2:3:4:5:6:7        => 3:5:8:2:11:13:15

2:3:4:5:6:7:8   1:2:3:4:5:6:7 1      => 1:1:1:1:1:1:1

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

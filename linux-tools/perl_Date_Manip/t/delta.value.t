#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'value';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $err = $obj->set(@test);
  if ($err) {
     return $obj->err();
  } else {
     $val = $obj->value();
     return $val;
  }
}

$obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

$tests="

delta    [ 0 0 0 0 10 20 30 ]                   => 0:0:0:0:10:20:30

delta    [ 0 0 0 0 10 20 30 ]      nonormalize  => 0:0:0:0:10:20:30

delta    [ -10 20 30 ]                          => 0:0:0:0:-9:39:30

delta    [ -10 20 30 ]             nonormalize  => 0:0:0:0:-10:+20:30

delta    [ 10 -70 -130 +90 ]                    => 0:0:1:3:-72:8:30

delta    [ 10 -70 -130 +90 ]       nonormalize  => 0:0:0:10:-70:130:+90

delta    [ 1 13 2 10 -70 -130 90 ]              => 2:1:3:3:-72:8:30

#

business [ 0 0 0 0 10 20 30 ]                   => 0:0:0:1:1:20:30

business [ 0 0 0 0 10 20 30 ]      nonormalize  => 0:0:0:0:10:20:30

business [ 1 13 2 10 -70 -130 90 ]              => 2:1:2:1:8:51:30

#

standard [ 1 13 2 10 -70 -130 90 ] nonormalize  => 1:13:2:10:-70:130:+90

m        25                        nonormalize  => 1:13:2:10:-70:+25:90

m        -135                                   => 2:1:3:3:-72:13:30

#

standard [ 1 13 2 10 -70 -130 90 ] nonormalize  => 1:13:2:10:-70:130:+90

M        14                                     => 2:2:3:3:-72:8:30

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

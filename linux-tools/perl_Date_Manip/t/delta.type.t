#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'type';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@args) = @_;
  if (@args == 1) {
    ($type) = @args;
    return $obj->type($type);
  } else {
    ($op,$val) = @args;
    $obj->set($op,$val);
    return 0
  }
}

$obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

$tests="

normal [ 0 0 0 0 1 2 3 ]   => 0

business                   => 0

standard                   => 1

exact                      => 1

semi                       => 0

approx                     => 0

###

normal [ 0 0 1 2 1 2 3 ]   => 0

business                   => 0

standard                   => 1

exact                      => 0

semi                       => 1

approx                     => 0

###

delta [ 1 0 0 0 1 2 3 ]    => 0

business                   => 0

standard                   => 1

exact                      => 0

semi                       => 0

approx                     => 1

###

business [ 0 0 0 0 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 1

semi                       => 0

approx                     => 0

###

business [ 0 0 0 1 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 1

semi                       => 0

approx                     => 0

###

business [ 0 0 1 2 1 2 3 ] => 0

business                   => 1

standard                   => 0

exact                      => 0

semi                       => 1

approx                     => 0

###

delta [ 1 0 0 0 10 20 30 ] => 0

business                   => 1

standard                   => 0

exact                      => 0

semi                       => 0

approx                     => 1

###

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

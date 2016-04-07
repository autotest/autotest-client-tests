#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'secs_since_1970_GMT(date->secs)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $obj->parse($test[0]);
  $ret = $obj->secs_since_1970_GMT();
  return $ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

$tests="

1997121007:00:00 => 881755200

1999121007:30:30 => 944829030

2009102009:51:37 => 1256046697

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

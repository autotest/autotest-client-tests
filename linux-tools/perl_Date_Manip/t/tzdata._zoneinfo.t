#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter '_zoneInfo';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');

$t->use_ok('Date::Manip::TZdata');

if ( -d "$testdir/../tzdata" ) {
  $obj = new Date::Manip::TZdata("$testdir/..");
} else {
  $t->skip_all('No tzdata directory');
}

sub test {
  (@test)=@_;
  return $obj->_zoneInfo(@test);
}

$tests="

America/Chicago rules 1800 => - 1

America/Chicago rules 1883 => - 1 US 2

America/Chicago rules 1919 => US 2

America/Chicago rules 1920 => Chicago 2

America/Chicago rules 1936 => Chicago 2 - 1 Chicago 2

Africa/Gaborone rules 1943 => - 1 01:00:00 3

Africa/Gaborone rules 1944 => 01:00:00 3 - 1

Atlantic/Cape_Verde rules 1975 => - 1 - 1

Asia/Tbilisi rules 1996 => E-EurAsia 2 01:00:00 3

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

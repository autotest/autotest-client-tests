#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'SetTime';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  return Date_SetTime(@_);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");

$tests="

'Jan 1, 1996 at 10:30' 12:40       => 1996010112:40:00

1996010110:30:40       12:40:50    => 1996010112:40:50

1996010110:30:40       12:40       => 1996010112:40:00

1996010110:30:40       12 40       => 1996010112:40:00

1996010110:30:40       12 40 50    => 1996010112:40:50

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

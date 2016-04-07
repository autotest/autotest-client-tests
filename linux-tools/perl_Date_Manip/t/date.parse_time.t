#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse_time';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  if ($test[0] eq "config") {
     shift(@test);
     $obj->config(@test);
     return ();
  }

  $obj->_init();
  my $err = $obj->parse_time(@test);
  if ($err) {
     return $obj->err();
  } else {
     $d1 = $obj->value();
     return $d1;
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-01:02:03, America/New_York");

$tests="

# Times

17:30:15 => 2000012117:30:15

'17:30:15 AM' => '[parse_time] Invalid time string'

'5:30:15 PM' => 2000012117:30:15

5:30:15 => 2000012105:30:15

17:30:15.25 => 2000012117:30:15

'17:30:15.25 AM' => '[parse_time] Invalid time string'

'5:30:15.25 PM' => 2000012117:30:15

5:30:15.25 => 2000012105:30:15

17:30.25 => 2000012117:30:15

'17:30.25 AM' => '[parse_time] Invalid time string'

'5:30.25 PM' => 2000012117:30:15

5:30.25 => 2000012105:30:15

17.5 => 2000012117:30:00

'17.5 AM' => '[parse_time] Invalid time string'

'5.5 PM' => 2000012117:30:00

5.5 => 2000012105:30:00

17:30 => 2000012117:30:00

'17:30 AM' => '[parse_time] Invalid time string'

'5:30 PM' => 2000012117:30:00

5:30 => 2000012105:30:00

midnight => 2000012100:00:00

5:30 => 2000012105:30:00

5:30:02 => 2000012105:30:02

15:30:00 => 2000012115:30:00

5pm => 2000012117:00:00

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

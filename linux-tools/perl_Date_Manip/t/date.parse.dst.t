#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (DST changes)';
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

  my $err = $obj->parse(@test);
  if ($err) {
     return $obj->err();
  } else {
     $d1 = $obj->value();
     $d2 = $obj->value("gmt");
     return($d1,$d2);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

# For these tests, get rid of other timezones.

$dmt = $obj->tz();
$dmt->define_abbrev('EST','America/New_York');
$dmt->define_abbrev('EDT','America/New_York');
$dmt->define_offset('-050000','std','America/New_York');
$dmt->define_offset('-040000','std','America/New_York');

$tests="

#
# Spring forward: 2011-03-13 02:00 EST -> 2011-03-13 03:00 EDT
#

'2011-03-13 01:59:59 EST' => 2011031301:59:59 2011031306:59:59

'2011-03-13 02:00:00 EST' => 'Unable to determine timezone'

'2011-03-13 02:59:59 EDT' => 'Unable to determine timezone'

'2011-03-13 03:00:00 EDT' => 2011031303:00:00 2011031307:00:00


'2011-03-13 01:59:59 -05:00:00' => 2011031301:59:59 2011031306:59:59

'2011-03-13 02:00:00 -05:00:00' => 'Unable to determine timezone'

'2011-03-13 02:59:59 -04:00:00' => 'Unable to determine timezone'

'2011-03-13 03:00:00 -04:00:00' => 2011031303:00:00 2011031307:00:00

#
# Fall back: 2011-11-06 02:00 EDT -> 2011-11-06 01:00 EST
#

'2011-11-06 01:59:59 EDT' => 2011110601:59:59 2011110605:59:59

'2011-11-06 02:00:00 EDT' => 'Unable to determine timezone'

'2011-11-06 01:00:00 EST' => 2011110601:00:00 2011110606:00:00


'2011-11-06 01:59:59 -04:00:00' => 2011110601:59:59 2011110605:59:59

'2011-11-06 02:00:00 -04:00:00' => 'Unable to determine timezone'

'2011-11-06 01:00:00 -05:00:00' => 2011110601:00:00 2011110606:00:00

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

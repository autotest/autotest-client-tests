#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'convert';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($date,$isdst,@test)=@_;
  $obj->_init();
  $err = $obj->set("date",$date,$isdst);
  $err = $obj->convert(@test) if (! $err);
  if ($err) {
     return $obj->err();
  } else {
     $d1 = $obj->value();
     return($d1);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");

$tests="

[ 1985 01 01 00 30 00 ] 0 America/Chicago => 1984123123:30:00

[ 1985 01 01 12 00 00 ] 0 America/Chicago => 1985010111:00:00

[ 1985 04 28 01 00 00 ] 0 America/Chicago => 1985042800:00:00

[ 1985 04 28 03 00 00 ] 0 America/Chicago => 1985042801:00:00

[ 1985 04 28 03 30 00 ] 0 America/Chicago => 1985042801:30:00

[ 1985 04 28 04 00 00 ] 0 America/Chicago => 1985042803:00:00

[ 1985 10 27 00 30 00 ] 0 America/Chicago => 1985102623:30:00

[ 1985 10 27 01 00 00 ] 1 America/Chicago => 1985102700:00:00

[ 1985 10 27 01 30 00 ] 1 America/Chicago => 1985102700:30:00

[ 1985 10 27 01 00 00 ] 0 America/Chicago => 1985102701:00:00

[ 1985 10 27 01 30 00 ] 0 America/Chicago => 1985102701:30:00

[ 1985 10 27 02 00 00 ] 0 America/Chicago => 1985102701:00:00

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

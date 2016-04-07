#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (holidays)';
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
     return($d1);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:00:00,America/New_York");
$obj->config("ConfigFile","$testdir/Manip.cnf");

$tests="

'Christmas'               => 2000122500:00:00

'Christmas 2010'          => 2010122400:00:00

'2010 Christmas'          => 2010122400:00:00

'Christmas at noon'       => 2000122512:00:00

'Christmas 2010 at noon'  => 2010122412:00:00

'2010 Christmas at noon'  => 2010122412:00:00

'Mon Christmas'           => 2000122500:00:00

'Tue Christmas'           => '[parse] Day of week invalid'

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

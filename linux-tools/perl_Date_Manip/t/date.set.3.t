#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'set (Printable=0)';
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
     $d1 = $obj->value();
     $d2 = $obj->value("local");
     $d3 = $obj->value("gmt");
     return($d1,$d2,$d3);
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/Los_Angeles");

$tests="

date [ 1996 1 1 12 0 0 ]       => 1996010112:00:00 1996010112:00:00 1996010120:00:00

date [ 1996 13 1 12 0 0 ]      => '[set] Invalid date argument'

date [ 1991 04 07 02 15 00 ]   => '[set] Invalid date/timezone'

date [ 1926 09 26 01 15 00 ] 0 => 1926092601:15:00 1926092601:15:00 1926092609:15:00

zdate America/Chicago [ 2005 06 01 12 00 00 ]
                               => 2005060112:00:00 2005060110:00:00 2005060117:00:00

zdate [ 1996 01 01 12 00 00 ]  => 1996010112:00:00 1996010112:00:00 1996010120:00:00

time [ 12 40 50 ]              => 1996010112:40:50 1996010112:40:50 1996010120:40:50

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

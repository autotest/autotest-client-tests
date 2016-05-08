#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (misc,DefaultTime=curr)';
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
$obj->config("forcedate","2000-01-21-12:00:00,America/New_York");
$obj->config("defaulttime","curr");

$tests="

Friday => 2000012112:00:00 2000012117:00:00

'Friday at 13:00' => 2000012113:00:00 2000012118:00:00

Monday => 2000011712:00:00 2000011717:00:00

'Monday at 13:00' => 2000011713:00:00 2000011718:00:00

Saturday => 2000012212:00:00 2000012217:00:00

'Saturday at 13:00' => 2000012213:00:00 2000012218:00:00

'next year' => 2001012112:00:00 2001012117:00:00

'last year' => 1999012112:00:00 1999012117:00:00

'next month' => 2000022112:00:00 2000022117:00:00

'last month' => 1999122112:00:00 1999122117:00:00

'next week' => 2000012812:00:00 2000012817:00:00

'last week' => 2000011412:00:00 2000011417:00:00

'last week at 13:00' => 2000011413:00:00 2000011418:00:00

'next friday' => 2000012812:00:00 2000012817:00:00

'next sunday' => 2000012312:00:00 2000012317:00:00

'last friday' => 2000011412:00:00 2000011417:00:00

'last sunday' => 2000011612:00:00 2000011617:00:00

'last sunday at 13:00' => 2000011613:00:00 2000011618:00:00

'last tue in Jun 96' => 1996062512:00:00 1996062516:00:00

'last tueSday of Jan' => 2000012512:00:00 2000012517:00:00

'last day in October 1997' => 1997103112:00:00 1997103117:00:00

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

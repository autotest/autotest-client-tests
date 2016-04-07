#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse_date (misc,DefaultTime=curr)';
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
  my $err = $obj->parse_date(@test);
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

Friday => 2000012100:00:00 2000012105:00:00

Monday => 2000011700:00:00 2000011705:00:00

Saturday => 2000012200:00:00 2000012205:00:00

'next year' => 2001012100:00:00 2001012105:00:00

'last year' => 1999012100:00:00 1999012105:00:00

'next month' => 2000022100:00:00 2000022105:00:00

'last month' => 1999122100:00:00 1999122105:00:00

'next week' => 2000012800:00:00 2000012805:00:00

'last week' => 2000011400:00:00 2000011405:00:00

'next friday' => 2000012800:00:00 2000012805:00:00

'next sunday' => 2000012300:00:00 2000012305:00:00

'last friday' => 2000011400:00:00 2000011405:00:00

'last sunday' => 2000011600:00:00 2000011605:00:00

'last tue in Jun 96' => 1996062500:00:00 1996062504:00:00

'last tueSday of Jan' => 2000012500:00:00 2000012505:00:00

'last day in October 1997' => 1997103100:00:00 1997103105:00:00

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

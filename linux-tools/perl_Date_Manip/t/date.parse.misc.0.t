#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (misc)';
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

$tests="

Friday => 2000012100:00:00 2000012105:00:00

'Friday at 13:00' => 2000012113:00:00 2000012118:00:00

Monday => 2000011700:00:00 2000011705:00:00

'Monday at 13:00' => 2000011713:00:00 2000011718:00:00

Saturday => 2000012200:00:00 2000012205:00:00

'Saturday at 13:00' => 2000012213:00:00 2000012218:00:00

###

'next friday' => 2000012800:00:00 2000012805:00:00

'next sunday' => 2000012300:00:00 2000012305:00:00

'last friday' => 2000011400:00:00 2000011405:00:00

'last sunday' => 2000011600:00:00 2000011605:00:00

'last sunday at 13:00' => 2000011613:00:00 2000011618:00:00

####

'next year' => 2001012100:00:00 2001012105:00:00

'last year' => 1999012100:00:00 1999012105:00:00

'next month' => 2000022100:00:00 2000022105:00:00

'last month' => 1999122100:00:00 1999122105:00:00

'next week' => 2000012800:00:00 2000012805:00:00

'last week' => 2000011400:00:00 2000011405:00:00

'last week at 13:00' => 2000011413:00:00 2000011418:00:00

###

'last day in October 1997' => 1997103100:00:00 1997103105:00:00

'last day in October' => 2000103100:00:00 2000103105:00:00

###

'last tue in Jun 96' => 1996062500:00:00 1996062504:00:00

'last tueSday of Jan' => 2000012500:00:00 2000012505:00:00

###

'last Tue in 1997' => 1997123000:00:00 1997123005:00:00

###

'first tue in Jun 1996' => 1996060400:00:00 1996060404:00:00

'3rd tuesday in Jun 96' => 1996061800:00:00 1996061804:00:00

'3rd tuesday in Jun 96 at 10:30am' => 1996061810:30:00 1996061814:30:00

'3rd tuesday in Jun 96 at 10:30 pm' => 1996061822:30:00 1996061902:30:00

'3rd tuesday in Jun 96 at 10:30 pm GMT' => 1996061822:30:00 1996061822:30:00

'3rd tuesday in Jun 96 at 10:30 pm CDT' => 1996061822:30:00 1996061903:30:00

'first tue in Jun' => 2000060600:00:00 2000060604:00:00

'3rd tuesday in Jun' => 2000062000:00:00 2000062004:00:00

###

'Dec 1st 1970' => 1970120100:00:00 1970120105:00:00

'Dec 1st' => 2000120100:00:00 2000120105:00:00

'1st Dec 1970' => 1970120100:00:00 1970120105:00:00

'1st Dec' => 2000120100:00:00 2000120105:00:00

'1970 Dec 1st' => 1970120100:00:00 1970120105:00:00

'1970 1st Dec' => 1970120100:00:00 1970120105:00:00

###

'22nd sunday' => 2000052800:00:00 2000052804:00:00

'twenty-second sunday 1996' => 1996060200:00:00 1996060204:00:00

'22nd sunday in 1996' => 1996060200:00:00 1996060204:00:00

###

'Friday week' => 2000012800:00:00 2000012805:00:00

'Monday week' => 2000012400:00:00 2000012405:00:00

###

today => 2000012100:00:00 2000012105:00:00

'today at 14:30' => 2000012114:30:00 2000012119:30:00

tomorrow => 2000012200:00:00 2000012205:00:00

'tomorrow at 14:30' => 2000012214:30:00 2000012219:30:00

yesterday => 2000012000:00:00 2000012005:00:00

'yesterday at 14:30' => 2000012014:30:00 2000012019:30:00

'today week' => 2000012800:00:00 2000012805:00:00

'today week at 14:30' => 2000012814:30:00 2000012819:30:00

'tomorrow week' => 2000012900:00:00 2000012905:00:00

'tomorrow week at 14:30' => 2000012914:30:00 2000012919:30:00

'yesterday week' => 2000012700:00:00 2000012705:00:00

'yesterday week at 14:30' => 2000012714:30:00 2000012719:30:00

###

'sunday week 1 1999' => 1999011000:00:00 1999011005:00:00

'sunday 1st week 1999' => 1999011000:00:00 1999011005:00:00

'sunday week 1' => 2000010900:00:00 2000010905:00:00

'sunday 1st week' => 2000010900:00:00 2000010905:00:00

###

1st => 2000010100:00:00 2000010105:00:00

tenth => 2000011000:00:00 2000011005:00:00

###

now => 2000012112:00:00 2000012117:00:00

'epoch 0' => 1969123119:00:00 1970010100:00:00

'epoch 400000' => 1970010510:06:40 1970010515:06:40

'today week' => 2000012800:00:00 2000012805:00:00

'today week at 4:00' => 2000012804:00:00 2000012809:00:00

###

'5th Sunday in October 2010' => 2010103100:00:00 2010103104:00:00

'9th Sunday in October 2010' => '[parse] Invalid date string'

'Sunday, 3rd October 2010' => 2010100300:00:00 2010100304:00:00

'Monday, 3rd October 2010' => '[parse] Day of week invalid'

'3rd tuesday in Jun 96 at 10:30 pm CET' => 'Invalid timezone'

###

'sunday w 22 in 1996' => 1996060200:00:00 1996060204:00:00

'sunday 22nd w in 1996' => 1996060200:00:00 1996060204:00:00

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

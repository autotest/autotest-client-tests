#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse (French)';
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
     return $d1;
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");
$obj->config("language","French","dateformat","nonUS");

($currS,$currMN,$currH,$currD,$currM,$currY)=("45","30","12","21","01","2000");

$now           = "${currY}${currM}${currD}${currH}:${currMN}:${currS}";
$today         = "${currY}${currM}${currD}00:00:00";
$yesterdaydate = "${currY}${currM}". ${currD}-1;
$tomorrowdate  = "${currY}${currM}". ${currD}+1;
$yesterday     = "${yesterdaydate}00:00:00";
$tomorrow      = "${tomorrowdate}00:00:00";

$tests="

'5-3-2009 5:30 du soir' => 2009030517:30:00

'5-3-2009 a 5:30 du soir' => 2009030517:30:00

'5-3-2009 a 5:30:45 du soir' => 2009030517:30:45

'5-3-2009 a 5h30:45 du soir' => 2009030517:30:45

aujourd'hui => $today

maintenant => $now

hier => $yesterday

demain => $tomorrow

'dernier mar en Juin 96' => 1996062500:00:00

'dernier mar de Juin' => ${currY}062700:00:00

'premier mar de Juin 1996' => 1996060400:00:00

'premier mar de Juin' => ${currY}060600:00:00

'3e mardi de Juin 96' => 1996061800:00:00

'3e mardi de Juin 96 a 12:00' => 1996061812:00:00

'3e mardi de Juin 96 a 10:30 du matin' => 1996061810:30:00

'3e mardi de Juin 96 a 10:30 du soir' => 1996061822:30:00


'SepT 10 65' => 1965091000:00:00

'SepT 10 1965' => 1965091000:00:00

'Septembre 10 65' => 1965091000:00:00

'Septembre 10 1965' => 1965091000:00:00

'Septembre10 1965' => 1965091000:00:00

'Septembre10 1965 12:00' => 1965091012:00:00

'Septembre-10-1965 12:00' => 1965091012:00:00

'Septembre/10/1965 12:00' => 1965091012:00:00

'12:00 Septembre10 1965' => 1965091012:00:00

'12:00 Septembre-10-1965' => 1965091012:00:00

'10 SepT 65' => 1965091000:00:00

'10 SepT 1965' => 1965091000:00:00

'10 Septembre 65' => 1965091000:00:00

'10 Septembre 1965' => 1965091000:00:00

10SepT65 => 1965091000:00:00

10SepT1965 => 1965091000:00:00

10Septembre65 => 1965091000:00:00

'10Septembre 1965' => 1965091000:00:00

'SepT 10 4:50' => ${currY}091004:50:00

'Septembre 10 4:50' => ${currY}091004:50:00

'SepT 10 4:50:40' => ${currY}091004:50:40

'Septembre 10 4:50:42' => ${currY}091004:50:42

'10 SepT 4:50' => ${currY}091004:50:00

'10 Septembre 4:50' => ${currY}091004:50:00

'10SepT 4:50' => ${currY}091004:50:00

'10Septembre 4:50' => ${currY}091004:50:00

'10 SepT 4:50:51' => ${currY}091004:50:51

'10 Septembre 4:50:52' => ${currY}091004:50:52

'10SepT 4:50:53' => ${currY}091004:50:53

'10Septembre 4:50:54' => ${currY}091004:50:54

'10Septembre95 4:50:54' => 1995091004:50:54

'Sept1065 4:50:53' => 1965091004:50:53

'Sept101965 4:50:53' => 1965091004:50:53

'4:50 SepT 10' => ${currY}091004:50:00

'4:50 Septembre 10' => ${currY}091004:50:00

'4:50:40 SepT 10' => ${currY}091004:50:40

'4:50:42 Septembre 10' => ${currY}091004:50:42

'4:50 10 SepT' => ${currY}091004:50:00

'4:50 10 Septembre' => ${currY}091004:50:00

'4:50 10SepT' => ${currY}091004:50:00

'4:50 10Septembre' => ${currY}091004:50:00

'4:50:51 10 SepT' => ${currY}091004:50:51

'4:50:52 10 Septembre' => ${currY}091004:50:52

'4:50:53 10SepT' => ${currY}091004:50:53

'4:50:54 10Septembre' => ${currY}091004:50:54

'SepT 1 5:30' => ${currY}090105:30:00

'SepT 10 05:30' => ${currY}091005:30:00

'SepT 10 05:30:11' => ${currY}091005:30:11

'SepT 1 65' => 1965090100:00:00

'SepT 1 1965' => 1965090100:00:00

'Septembre 1 5:30' => ${currY}090105:30:00

'Septembre 10 05:30' => ${currY}091005:30:00

'Septembre 10 05h30:12' => ${currY}091005:30:12

'Septembre 1 65' => 1965090100:00:00

'Septembre 1 1965' => 1965090100:00:00

'5:30 SepT 1' => ${currY}090105:30:00

'05:30 SepT 10' => ${currY}091005:30:00

'05:30:11 SepT 10' => ${currY}091005:30:11

'5:30 Septembre 1' => ${currY}090105:30:00

'05:30 Septembre 10' => ${currY}091005:30:00

'05:30:12 du matin Septembre 10' => ${currY}091005:30:12

'05:30:12 du soir Septembre 10' => ${currY}091017:30:12

'1 SepT 65' => 1965090100:00:00

'1 SepT 1965' => 1965090100:00:00

'1 Septembre 65' => 1965090100:00:00

'1 Septembre 1965' => 1965090100:00:00

'1 12 65' => 1965120100:00:00

'1 12 1965' => 1965120100:00:00

'29 2 92' => 1992022900:00:00

'2 29 92' => '[parse] Invalid date'

'2 29 90' => '[parse] Invalid date'

'1er SepT 65' => 1965090100:00:00

'SepT premier 1965' => 1965090100:00:00

'Fevrier 3, 2002' => 2002020300:00:00

'février 3, 2002' => 2002020300:00:00

'f\xE9vrier 3, 2002' => 2002020300:00:00

'f\x{e9}vrier 3, 2002' => 2002020300:00:00

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

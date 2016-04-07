#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,delta,business 8:00-5:00)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
Date_Init(qw( PersonalCnf=Manip5.cnf PathSep=! PersonalCnfPath=./t!. IgnoreGlobalCnf=1 ));
Date_Init("WorkDayBeg=08:00","WorkDayEnd=17:00");

$tests="

'Wed Nov 20 1996 noon' +0:5:0:0             2 => 1996112108:00:00

'Wed Nov 20 1996 noon' +0:2:0:0             2 => 1996112014:00:00

'Wed Nov 20 1996 noon' +3:2:0:0             2 => 1996112514:00:00

'Wed Nov 20 1996 noon' -3:2:0:0             2 => 1996111510:00:00

'Wed Nov 20 1996 noon' +3:7:0:0             2 => 1996112610:00:00

'Wed Nov 20 1996 noon' +6:2:0:0             2 => 1996112914:00:00

'Dec 31 1996 noon'     +1:2:0:0             2 => 1997010214:00:00

'Dec 30 1996 noon'     +1:2:0:0             2 => 1996123114:00:00

'Mar 31 1997 16:59:59' '+ 1 sec'            2 => 1997040108:00:00

'Wed Nov 20 1996 noon' +0:0:1:0:0:0:0       2 => 1996112712:00:00

2002120600:00:00       '- business 4 hours' 2 => 2002120513:00:00

2002120600:00:01       '- business 4 hours' 2 => 2002120513:00:00

2002120523:59:59       '- business 4 hours' 2 => 2002120513:00:00

2002120602:00:00       '- business 4 hours' 2 => 2002120513:00:00

2002120609:00:00       '- business 4 hours' 2 => 2002120514:00:00

2002120609:00:10       '- business 4 hours' 2 => 2002120514:00:10

2002120611:00:00       '- business 4 hours' 2 => 2002120516:00:00

2002120612:00:00       '- business 4 hours' 2 => 2002120608:00:00

2002120512:00:00       '+ business 4 hours' 2 => 2002120516:00:00

2002120514:00:00       '+ business 4 hours' 2 => 2002120609:00:00

2002120522:00:00       '+ business 4 hours' 2 => 2002120612:00:00

2002120523:59:59       '+ business 4 hours' 2 => 2002120612:00:00

2002120602:00:00       '+ business 4 hours' 2 => 2002120612:00:00

2002120609:00:00       '+ business 4 hours' 2 => 2002120613:00:00

20060616               '+1 business day'    2 => 2006061908:00:00
";

$t->tests(func  => \&DateCalc,
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

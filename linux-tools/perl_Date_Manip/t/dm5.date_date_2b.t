#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,date,business 8:00-5:00)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");
Date_Init(qw( PersonalCnf=Manip5.cnf PathSep=! PersonalCnfPath=./t!. IgnoreGlobalCnf=1 ));
Date_Init("WorkDayBeg=8:00","WorkDayEnd=17:00");

$tests="
'Wed Jan 10 1996 noon'      'Wed Feb 7 1996 noon'        3 => +0:0:0:19:0:0:0

'Wed Feb 7 1996 noon'       'Wed Jan 10 1996 noon'       3 => -0:0:0:19:0:0:0

'Tue Jan 9 1996 12:00:00'   'Tue Jan 9 1996 14:30:30'    3 => +0:0:0:0:2:30:30

'Tue Jan 9 1996 14:30:30'   'Tue Jan 9 1996 12:00:00'    3 => -0:0:0:0:2:30:30

'Tue Jan 9 1996 12:00:00'   'Wed Jan 10 1996 14:30:30'   3 => +0:0:0:1:2:30:30

'Wed Jan 10 1996 14:30:30'  'Tue Jan 9 1996 12:00:00'    3 => -0:0:0:1:2:30:30

'Tue Jan 9 1996 12:00:00'   'Wed Jan 10 1996 10:30:30'   3 => +0:0:0:0:7:30:30

'Wed Jan 10 1996 10:30:30'  'Tue Jan 9 1996 12:00:00'    3 => -0:0:0:0:7:30:30

'Mon Dec 30 1996 noon'      'Mon Jan 6 1997 noon'        3 => +0:0:0:4:0:0:0

'Mon Jan 6 1997 noon'       'Mon Dec 30 1996 noon'       3 => -0:0:0:4:0:0:0

'Fri Feb 11 2005 16:00:43'  'Fri Feb 11 2005 16:44:09'   3 => +0:0:0:0:0:43:26

'02/11/2005 04:00:43 PM'    '02/11/2005 04:44:09 PM'     3 => +0:0:0:0:0:43:26

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

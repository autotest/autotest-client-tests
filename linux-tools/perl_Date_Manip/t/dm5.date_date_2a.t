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

'Jun 1 1999'                 'Jun 4 1999'               2 => +0:0:0:2:0:0:0

'Wed Jan 10 1996 noon'       'Wed Jan 7 1998 noon'      2 => +1:11:0:18:0:0:0

'Wed Jan 7 1998 noon'        'Wed Jan 10 1996 noon'     2 => -1:11:0:18:0:0:0

'Wed Jan 10 1996 noon'       'Wed Jan 8 1997 noon'      2 => +0:11:0:19:0:0:0

'Wed Jan 8 1997 noon'        'Wed Jan 10 1996 noon'     2 => -0:11:0:19:0:0:0

'Wed May 8 1996 noon'        'Wed Apr 9 1997 noon'      2 => +0:11:0:1:0:0:0

'Wed Apr 9 1997 noon'        'Wed May 8 1996 noon'      2 => -0:11:0:1:0:0:0

'Wed Apr 10 1996 noon'       'Wed May 14 1997 noon'     2 => +1:1:0:2:4:0:0

'Wed May 14 1997 noon'       'Wed Apr 10 1996 noon'     2 => -1:1:0:2:4:0:0

'Wed Jan 10 1996 noon'       'Wed Feb 7 1996 noon'      2 => +0:0:0:19:0:0:0

'Wed Feb 7 1996 noon'        'Wed Jan 10 1996 noon'     2 => -0:0:0:19:0:0:0

'Mon Jan 8 1996 noon'        'Fri Feb 9 1996 noon'      2 => +0:1:0:1:0:0:0

'Fri Feb 9 1996 noon'        'Mon Jan 8 1996 noon'      2 => -0:1:0:1:0:0:0

'Tue Jan 9 1996 12:00:00'    'Tue Jan 9 1996 14:30:30'  2 => +0:0:0:0:2:30:30

'Tue Jan 9 1996 14:30:30'    'Tue Jan 9 1996 12:00:00'  2 => -0:0:0:0:2:30:30

'Tue Jan 9 1996 12:00:00'    'Wed Jan 10 1996 14:30:30' 2 => +0:0:0:1:2:30:30

'Wed Jan 10 1996 14:30:30'   'Tue Jan 9 1996 12:00:00'  2 => -0:0:0:1:2:30:30

'Tue Jan 9 1996 12:00:00'    'Wed Jan 10 1996 10:30:30' 2 => +0:0:0:0:7:30:30

'Wed Jan 10 1996 10:30:30'   'Tue Jan 9 1996 12:00:00'  2 => -0:0:0:0:7:30:30

'Tue Jan 9 1996 12:00:00'    'Fri Jan 10 1997 10:30:30' 2 => +1:0:0:0:7:30:30

'Fri Jan 10 1997 10:30:30'   'Tue Jan 9 1996 12:00:00'  2 => -1:0:0:0:7:30:30

'Mon Dec 30 1996 noon'       'Mon Jan 6 1997 noon'      2 => +0:0:0:4:0:0:0

'Mon Jan 6 1997 noon'        'Mon Dec 30 1996 noon'     2 => -0:0:0:4:0:0:0

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

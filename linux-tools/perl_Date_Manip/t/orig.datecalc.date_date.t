#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,date)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  return DateCalc(@_);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=$testdir/Manip.cnf");

$tests="

# Exact

'Jan 1 1996 12:00:00'   'Jan 1 1996 14:30:30'   => 0:0:0:0:2:30:30

'Jan 1 1996 14:30:30'   'Jan 1 1996 12:00:00'   => 0:0:0:0:-2:30:30

'Jan 1 1996 12:00:00'   'Jan 2 1996 14:30:30'   => 0:0:0:0:26:30:30

'Jan 2 1996 14:30:30'   'Jan 1 1996 12:00:00'   => 0:0:0:0:-26:30:30

'Jan 1 1996 12:00:00'   'Jan 2 1996 10:30:30'   => 0:0:0:0:22:30:30

'Jan 2 1996 10:30:30'   'Jan 1 1996 12:00:00'   => 0:0:0:0:-22:30:30

'Jan 1 1996 12:00:00'   'Jan 2 1997 10:30:30'   => 0:0:0:0:8806:30:30

'Jan 2 1997 10:30:30'   'Jan 1 1996 12:00:00'   => 0:0:0:0:-8806:30:30

'Jan 1st 1997 00:00:01' 'Feb 1st 1997 00:00:00' => 0:0:0:0:743:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1997 00:00:00' => 0:0:0:0:1415:59:59

'Jan 1st 1997 00:00:01' 'Mar 1st 1998 00:00:00' => 0:0:0:0:10175:59:59

# Approximate

'Wed Jan 10 1996 noon'  'Wed Jan 7 1998 noon'   1 => 2:0:0:-3:0:0:0

'Wed Jan 7 1998 noon'   'Wed Jan 10 1996 noon'  1 => -2:0:0:+3:0:0:0

'Wed Jan 10 1996 noon'  'Wed Jan 8 1997 noon'   1 => 1:0:0:-2:0:0:0

'Wed Jan 8 1997 noon'   'Wed Jan 10 1996 noon'  1 => -1:0:0:+2:0:0:0

'Wed May 8 1996 noon'   'Wed Apr 9 1997 noon'   1 => 0:11:0:1:0:0:0

'Wed Apr 9 1997 noon'   'Wed May 8 1996 noon'   1 => 0:-11:0:1:0:0:0

'Wed Apr 10 1996 noon'  'Wed May 14 1997 noon'  1 => 1:1:0:4:0:0:0

'Wed May 14 1997 noon'  'Wed Apr 10 1996 noon'  1 => -1:1:0:4:0:0:0

'Wed Jan 10 1996 noon'  'Wed Feb 7 1996 noon'   1 => 0:1:0:-3:0:0:0

'Wed Feb 7 1996 noon'   'Wed Jan 10 1996 noon'  1 => 0:-1:0:+3:0:0:0

'Mon Jan 8 1996 noon'   'Fri Feb 9 1996 noon'   1 => 0:1:0:1:0:0:0

'Fri Feb 9 1996 noon'   'Mon Jan 8 1996 noon'   1 => 0:-1:0:1:0:0:0

'Jan 1 1996 12:00:00'   'Jan 1 1996 14:30:30'   1 => 0:0:0:0:2:30:30

'Jan 1 1996 14:30:30'   'Jan 1 1996 12:00:00'   1 => 0:0:0:0:-2:30:30

'Jan 1 1996 12:00:00'   'Jan 2 1996 14:30:30'   1 => 0:0:0:1:2:30:30

'Jan 2 1996 14:30:30'   'Jan 1 1996 12:00:00'   1 => 0:0:0:-1:2:30:30

'Jan 1 1996 12:00:00'   'Jan 2 1996 10:30:30'   1 => 0:0:0:1:-1:29:30

'Jan 2 1996 10:30:30'   'Jan 1 1996 12:00:00'   1 => 0:0:0:-1:+1:29:30

'Jan 1 1996 12:00:00'   'Jan 2 1997 10:30:30'   1 => 1:0:0:1:-1:29:30

'Jan 2 1997 10:30:30'   'Jan 1 1996 12:00:00'   1 => -1:0:0:1:+1:29:30

'Jan 31 1996 12:00:00'  'Feb 28 1997 10:30:30'  1 => 1:1:0:0:-1:29:30

'Feb 28 1997 10:30:30'  'Jan 31 1996 12:00:00'  1 => -1:1:0:+3:1:29:30

'Jan 1st 1997 00:00:01' 'Feb 1st 1997 00:00:00' 1 => 0:1:0:0:0:0:-1

'Jan 1st 1997 00:00:01' 'Mar 1st 1997 00:00:00' 1 => 0:2:0:0:0:0:-1

'Jan 1st 1997 00:00:01' 'Mar 1st 1998 00:00:00' 1 => 1:2:0:0:0:0:-1

# Business approximate

'Jun 1 1999' 'Jun 4 1999' 2 => 0:0:0:2:0:0:0

'Wed Jan 10 1996 noon' 'Wed Jan 7 1998 noon' 2 => 2:0:0:-2:5:0:0

'Wed Jan 7 1998 noon' 'Wed Jan 10 1996 noon' 2 => -2:0:0:+2:4:0:0

'Wed Jan 10 1996 noon' 'Wed Jan 8 1997 noon' 2 => 1:0:0:-2:0:0:0

'Wed Jan 8 1997 noon' 'Wed Jan 10 1996 noon' 2 => -1:0:0:+2:0:0:0

'Wed May 8 1996 noon' 'Wed Apr 9 1997 noon' 2 => 0:11:0:1:0:0:0

'Wed Apr 9 1997 noon' 'Wed May 8 1996 noon' 2 => 0:-11:0:1:0:0:0

'Wed Apr 10 1996 noon' 'Wed May 14 1997 noon' 2 => 1:1:0:2:4:0:0

'Wed May 14 1997 noon' 'Wed Apr 10 1996 noon' 2 => -1:1:0:2:5:0:0

'Wed Jan 10 1996 noon' 'Wed Feb 7 1996 noon' 2 => 0:1:0:-2:5:0:0

'Wed Feb 7 1996 noon' 'Wed Jan 10 1996 noon' 2 => 0:-1:0:+2:4:0:0

'Mon Jan 8 1996 noon' 'Fri Feb 9 1996 noon' 2 => 0:1:0:1:0:0:0

'Fri Feb 9 1996 noon' 'Mon Jan 8 1996 noon' 2 => 0:-1:0:1:0:0:0

'Tue Jan 9 1996 12:00:00' 'Tue Jan 9 1996 14:30:30' 2 => 0:0:0:0:2:30:30

'Tue Jan 9 1996 14:30:30' 'Tue Jan 9 1996 12:00:00' 2 => 0:0:0:0:-2:30:30

'Tue Jan 9 1996 12:00:00' 'Wed Jan 10 1996 14:30:30' 2 => 0:0:0:1:2:30:30

'Wed Jan 10 1996 14:30:30' 'Tue Jan 9 1996 12:00:00' 2 => 0:0:0:-1:2:30:30

'Tue Jan 9 1996 12:00:00' 'Wed Jan 10 1996 10:30:30' 2 => 0:0:0:0:7:30:30

'Wed Jan 10 1996 10:30:30' 'Tue Jan 9 1996 12:00:00' 2 => 0:0:0:0:-7:30:30

'Tue Jan 9 1996 12:00:00' 'Fri Jan 10 1997 10:30:30' 2 => 1:0:0:0:7:30:30

'Fri Jan 10 1997 10:30:30' 'Tue Jan 9 1996 12:00:00' 2 => -1:0:0:0:7:30:30

'Mon Dec 30 1996 noon' 'Mon Jan 6 1997 noon' 2 => 0:1:-3:3:0:0:0

'Mon Jan 6 1997 noon' 'Mon Dec 30 1996 noon' 2 => 0:-1:+3:1:0:0:0

# Business exact

'Wed Jan 10 1996 noon' 'Wed Feb 7 1996 noon' 3 => 0:0:0:19:0:0:0

'Wed Feb 7 1996 noon' 'Wed Jan 10 1996 noon' 3 => 0:0:0:-19:0:0:0

'Tue Jan 9 1996 12:00:00' 'Tue Jan 9 1996 14:30:30' 3 => 0:0:0:0:2:30:30

'Tue Jan 9 1996 14:30:30' 'Tue Jan 9 1996 12:00:00' 3 => 0:0:0:0:-2:30:30

'Tue Jan 9 1996 12:00:00' 'Wed Jan 10 1996 14:30:30' 3 => 0:0:0:1:2:30:30

'Wed Jan 10 1996 14:30:30' 'Tue Jan 9 1996 12:00:00' 3 => 0:0:0:-1:2:30:30

'Tue Jan 9 1996 12:00:00' 'Wed Jan 10 1996 10:30:30' 3 => 0:0:0:0:7:30:30

'Wed Jan 10 1996 10:30:30' 'Tue Jan 9 1996 12:00:00' 3 => 0:0:0:0:-7:30:30

'Mon Dec 30 1996 noon' 'Mon Jan 6 1997 noon' 3 => 0:0:0:4:0:0:0

'Mon Jan 6 1997 noon' 'Mon Dec 30 1996 noon' 3 => 0:0:0:-4:0:0:0

'Fri Feb 11 2005 16:00:43' 'Fri Feb 11 2005 16:44:09' 3 => 0:0:0:0:0:43:26

'02/11/2005 04:00:43 PM' '02/11/2005 04:44:09 PM' 3 => 0:0:0:0:0:43:26

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

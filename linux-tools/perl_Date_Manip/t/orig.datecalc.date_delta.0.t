#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'DateCalc (date,delta)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
   my($d1,$d2) = (@_);
   DateCalc($d1,$d2);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=$testdir/Manip.cnf");

$tests="

# Exact deltas

'Wed Feb 7 1996 8:00' +1:1:1:1 => 1996020809:01:01

'Wed Nov 20 1996 noon' +0:5:0:0 => 1996112017:00:00

'Wed Nov 20 1996 noon' +0:13:0:0 => 1996112101:00:00

'Wed Nov 20 1996 noon' +3:2:0:0 => 1996112314:00:00

'Wed Nov 20 1996 noon' -3:2:0:0 => 1996111710:00:00

'Wed Nov 20 1996 noon' +3:13:0:0 => 1996112401:00:00

'Wed Nov 20 1996 noon' +6:2:0:0 => 1996112614:00:00

'Dec 31 1996 noon' +1:2:0:0 => 1997010114:00:00

'Jan 31 1997 23:59:59' '+ 1 sec' => 1997020100:00:00

'20050215 13:59:11' -10h => 2005021503:59:11

2005021513:59:11 '-10h +0s' => 2005021503:59:11

# Approx deltas

'Wed Feb 7 1996 8:00' +1:1:1:1 => 1996020809:01:01

'Wed Nov 20 1996 noon' +0:5:0:0 => 1996112017:00:00

'Wed Nov 20 1996 noon' +0:13:0:0 => 1996112101:00:00

'Wed Nov 20 1996 noon' +3:2:0:0 => 1996112314:00:00

'Wed Nov 20 1996 noon' -3:2:0:0 => 1996111710:00:00

'Wed Nov 20 1996 noon' +3:13:0:0 => 1996112401:00:00

'Wed Nov 20 1996 noon' +6:2:0:0 => 1996112614:00:00

'Dec 31 1996 noon' +1:2:0:0 => 1997010114:00:00

'Jan 31 1997 23:59:59' '+ 1 sec' => 1997020100:00:00

# Business deltas

'Wed Nov 20 1996 noon' '+0:5:0:0 business' => 1996112108:00:00

'Wed Nov 20 1996 noon' '+0:2:0:0 business' => 1996112014:00:00

'Wed Nov 20 1996 noon' '+3:2:0:0 business' => 1996112514:00:00

'Wed Nov 20 1996 noon' '-3:2:0:0 business' => 1996111510:00:00

'Wed Nov 20 1996 noon' '+3:7:0:0 business' => 1996112610:00:00

'Wed Nov 20 1996 noon' '+6:2:0:0 business' => 1996120214:00:00

'Dec 31 1996 noon' '+1:2:0:0 business' => 1997010214:00:00

'Dec 30 1996 noon' '+1:2:0:0 business' => 1996123114:00:00

'Mar 31 1997 16:59:59' '+ 1 sec' => 1997033117:00:00

'Mar 31 1997 16:59:59' '+ 1 sec business' => 1997040108:00:00

'Wed Nov 20 1996 noon' +0:0:1:0:0:0:0 => 1996112712:00:00

2002120600:00:00 '- business 4 hours' => 2002120513:00:00

2002120600:00:01 '- business 4 hours' => 2002120513:00:00

2002120523:59:59 '- business 4 hours' => 2002120513:00:00

2002120602:00:00 '- business 4 hours' => 2002120513:00:00

2002120609:00:00 '- business 4 hours' => 2002120514:00:00

2002120609:00:10 '- business 4 hours' => 2002120514:00:10

2002120611:00:00 '- business 4 hours' => 2002120516:00:00

2002120612:00:00 '- business 4 hours' => 2002120608:00:00

2002120512:00:00 '+ business 4 hours' => 2002120516:00:00

2002120514:00:00 '+ business 4 hours' => 2002120609:00:00

2002120522:00:00 '+ business 4 hours' => 2002120612:00:00

2002120523:59:59 '+ business 4 hours' => 2002120612:00:00

2002120602:00:00 '+ business 4 hours' => 2002120612:00:00

2002120609:00:00 '+ business 4 hours' => 2002120613:00:00

20060616 '+1 business day' => 2006061908:00:00

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

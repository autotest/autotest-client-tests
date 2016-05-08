#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter '_critical_date';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
   (@test)=@_;
   @ret = $obj->_critical_date(@test);
   return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

#################################################################################
# Rule    Syria   2008    max     -       Apr     Fri>=1  0:00    1:00    S
# Rule    Syria   2008    max     -       Oct     1       0:00    0       -

# Zone    Asia/Damascus   2:25:12 -       LMT     1920    # Dimashq
#                         2:00    Syria   EE%sT

# Asia/Damascus  Apr  1 21:59:59 2038 UTC = Thu Apr  1 23:59:59 2038 EET isdst=0
# Asia/Damascus  Apr  1 22:00:00 2038 UTC = Fri Apr  2 01:00:00 2038 EEST isdst=1
# Asia/Damascus  Sep 30 20:59:59 2038 UTC = Thu Sep 30 23:59:59 2038 EEST isdst=1
# Asia/Damascus  Sep 30 21:00:00 2038 UTC = Thu Sep 30 23:00:00 2038 EET isdst=0
# Asia/Damascus  Mar 31 21:59:59 2039 UTC = Thu Mar 31 23:59:59 2039 EET isdst=0
# Asia/Damascus  Mar 31 22:00:00 2039 UTC = Fri Apr  1 01:00:00 2039 EEST isdst=1
# Asia/Damascus  Sep 30 20:59:59 2039 UTC = Fri Sep 30 23:59:59 2039 EEST isdst=1
# Asia/Damascus  Sep 30 21:00:00 2039 UTC = Fri Sep 30 23:00:00 2039 EET isdst=0
# Asia/Damascus  Apr  5 21:59:59 2040 UTC = Thu Apr  5 23:59:59 2040 EET isdst=0

#################################################################################
# Rule    US      2007    max     -       Mar     Sun>=8  2:00    1:00    D
# Rule    US      2007    max     -       Nov     Sun>=1  2:00    0       S

# Zone America/New_York   -4:56:02 -      LMT     1883 Nov 18 12:03:58
#                         -5:00   US      E%sT    1920
#                         -5:00   NYC     E%sT    1942
#                         -5:00   US      E%sT    1946
#                         -5:00   NYC     E%sT    1967
#                         -5:00   US      E%sT

# America/New_York  Mar  8 06:59:59 2037 UTC = Mar  8 01:59:59 2037 EST isdst=0
# America/New_York  Mar  8 07:00:00 2037 UTC = Mar  8 03:00:00 2037 EDT isdst=1
# America/New_York  Nov  1 05:59:59 2037 UTC = Nov  1 01:59:59 2037 EDT isdst=1
# America/New_York  Nov  1 06:00:00 2037 UTC = Nov  1 01:00:00 2037 EST isdst=0
# America/New_York  Mar 14 06:59:59 2038 UTC = Mar 14 01:59:59 2038 EST isdst=0
# America/New_York  Mar 14 07:00:00 2038 UTC = Mar 14 03:00:00 2038 EDT isdst=1
# America/New_York  Nov  7 05:59:59 2038 UTC = Nov  7 01:59:59 2038 EDT isdst=1
# America/New_York  Nov  7 06:00:00 2038 UTC = Nov  7 01:00:00 2038 EST isdst=0

#################################################################################
# Rule    Egypt   1995    max     -       Apr     lastFri  0:00s  1:00    S
# Rule    Egypt   2008    max     -       Aug     lastThu 23:00s  0       -

# Zone    Africa/Cairo    2:05:00 -       LMT     1900 Oct
#                         2:00    Egypt   EE%sT

# Africa/Cairo  Thu Apr 25 21:59:59 2030 UTC = Thu Apr 25 23:59:59 2030 EET isdst=0
# Africa/Cairo  Thu Apr 25 22:00:00 2030 UTC = Fri Apr 26 01:00:00 2030 EEST isdst=1
# Africa/Cairo  Thu Aug 29 20:59:59 2030 UTC = Thu Aug 29 23:59:59 2030 EEST isdst=1
# Africa/Cairo  Thu Aug 29 21:00:00 2030 UTC = Thu Aug 29 23:00:00 2030 EET isdst=0
# Africa/Cairo  Thu Apr 24 21:59:59 2031 UTC = Thu Apr 24 23:59:59 2031 EET isdst=0

#################################################################################
# Rule    StJohns 2007    max     -       Mar     Sun>=8  0:01    1:00    D
# Rule    StJohns 2007    max     -       Nov     Sun>=1  0:01    0       S

# Zone America/St_Johns   -3:30:52 -      LMT     1884
#                         -3:30:52 StJohns N%sT   1918
#                         -3:30:52 Canada N%sT    1919
#                         -3:30:52 StJohns N%sT   1935 Mar 30
#                         -3:30   StJohns N%sT    1942 May 11
#                         -3:30   Canada  N%sT    1946
#                         -3:30   StJohns N%sT

# America/St_Johns  Mar  8 03:30:59 2037 UTC = Mar  8 00:00:59 2037 NST isdst=0
# America/St_Johns  Mar  8 03:31:00 2037 UTC = Mar  8 01:01:00 2037 NDT isdst=1
# America/St_Johns  Nov  1 02:30:59 2037 UTC = Nov  1 00:00:59 2037 NDT isdst=1
# America/St_Johns  Nov  1 02:31:00 2037 UTC = Oct 31 23:01:00 2037 NST isdst=0

#################################################################################
# Rule    EU      1981    max     -       Mar     lastSun  1:00u  1:00    S
# Rule    EU      1996    max     -       Oct     lastSun  1:00u  0       -

# Zone America/Godthab    -3:26:56 -      LMT     1916 Jul 28 # Nuuk
#                         -3:00   -       WGT     1980 Apr  6 2:00
#                         -3:00   EU      WG%sT

# America/Godthab  Mar 29 00:59:59 2037 UTC = Mar 28 21:59:59 2037 WGT isdst=0
# America/Godthab  Mar 29 01:00:00 2037 UTC = Mar 28 23:00:00 2037 WGST isdst=1
# America/Godthab  Oct 25 00:59:59 2037 UTC = Oct 24 22:59:59 2037 WGST isdst=1
# America/Godthab  Oct 25 01:00:00 2037 UTC = Oct 24 22:00:00 2037 WGT isdst=0

#################################################################################

# YEAR MON FLAG NUM DOW ISDST TIME TIMETYPE STDOFF DSTOFF
$tests="

2038 04 ge 1 5 1 00:00:00 w 02:00:00 03:00:00 =>
   [ 2038 4 1 21 59 59 ]
   [ 2038 4 1 23 59 59 ]
   [ 2038 4 1 22 0 0 ]
   [ 2038 4 2 1 0 0 ]

2038 10 dom 1 - 0 00:00:00 w 02:00:00 03:00:00 =>
   [ 2038 9 30 20 59 59 ]
   [ 2038 9 30 23 59 59 ]
   [ 2038 9 30 21 0 0 ]
   [ 2038 9 30 23 0 0 ]

2037 03 ge 8 7 1 02:00:00 w -05:00:00 -04:00:00 =>
   [ 2037 3 8 6 59 59 ]
   [ 2037 3 8 1 59 59 ]
   [ 2037 3 8 7 0 0 ]
   [ 2037 3 8 3 0 0 ]

2037 11 ge 1 7 0 02:00:00 w -05:00:00 -04:00:00 =>
   [ 2037 11 1 5 59 59 ]
   [ 2037 11 1 1 59 59 ]
   [ 2037 11 1 6 0 0 ]
   [ 2037 11 1 1 0 0 ]

2030 04 last - 5 1 00:00:00 s 02:00:00 03:00:00 =>
   [ 2030 4 25 21 59 59 ]
   [ 2030 4 25 23 59 59 ]
   [ 2030 4 25 22 0 0 ]
   [ 2030 4 26 1 0 0 ]

2030 08 last - 4 0 23:00:00 s 02:00:00 03:00:00 =>
   [ 2030 8 29 20 59 59 ]
   [ 2030 8 29 23 59 59 ]
   [ 2030 8 29 21 0 0 ]
   [ 2030 8 29 23 0 0 ]

2037 03 ge 8 7 1 00:01:00 w -03:30:00 -02:30:00 =>
   [ 2037 3 8 3 30 59 ]
   [ 2037 3 8 0 0 59 ]
   [ 2037 3 8 3 31 0 ]
   [ 2037 3 8 1 1 0 ]

2037 11 ge 1 7 0 00:01:00 w -03:30:00 -02:30:00 =>
   [ 2037 11 1 2 30 59 ]
   [ 2037 11 1 0 0 59 ]
   [ 2037 11 1 2 31 0 ]
   [ 2037 10 31 23 1 0 ]

2037 03 last - 7 1 01:00:00 u -03:00:00 -02:00:00 =>
   [ 2037 3 29 0 59 59 ]
   [ 2037 3 28 21 59 59 ]
   [ 2037 3 29 1 0 0 ]
   [ 2037 3 28 23 0 0 ]

2037 10 last - 7 0 01:00:00 u -03:00:00 -02:00:00 =>
   [ 2037 10 25 0 59 59 ]
   [ 2037 10 24 22 59 59 ]
   [ 2037 10 25 1 0 0 ]
   [ 2037 10 24 22 0 0 ]

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

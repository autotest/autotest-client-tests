#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'ParseRecur (English)';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");

$tests ="

'every 7th day in June 1999'
0
1999061500:00:00
1999063000:00:00
   =>
   1999062100:00:00
   1999062800:00:00

'every 7th day in June 1999'
1999061500:00:00
1999061500:00:00
1999063000:00:00
   =>
   1999061500:00:00
   1999062200:00:00
   1999062900:00:00

'every 7th day in June 1999'
   =>
   1999060700:00:00
   1999061400:00:00
   1999062100:00:00
   1999062800:00:00

'4th day of each month in 1999'
   =>
   1999010400:00:00
   1999020400:00:00
   1999030400:00:00
   1999040400:00:00
   1999050400:00:00
   1999060400:00:00
   1999070400:00:00
   1999080400:00:00
   1999090400:00:00
   1999100400:00:00
   1999110400:00:00
   1999120400:00:00

'2nd tuesday of every month in 1999'
   =>
   1999011200:00:00
   1999020900:00:00
   1999030900:00:00
   1999041300:00:00
   1999051100:00:00
   1999060800:00:00
   1999071300:00:00
   1999081000:00:00
   1999091400:00:00
   1999101200:00:00
   1999110900:00:00
   1999121400:00:00

'every 2nd tuesday in June 1999'
   =>
   1999060100:00:00
   1999061500:00:00
   1999062900:00:00

'every 6th tuesday in 1999'
   =>
   1999020900:00:00
   1999032300:00:00
   1999050400:00:00
   1999061500:00:00
   1999072700:00:00
   1999090700:00:00
   1999101900:00:00
   1999113000:00:00

";

$t->tests(func  => \&ParseRecur,
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

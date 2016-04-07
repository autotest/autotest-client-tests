#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'ParseDateDelta';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  return ParseDateDelta(@_);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");

$tests="

# Test weeks

'+ 4 week 3 day' => 0:0:4:3:0:0:0

'+ 4 wk 3 day 20:30' => __blank__

'+ 15mn' => 0:0:0:0:0:15:0

'+ 15 mn' => 0:0:0:0:0:15:0

'15 mn' => 0:0:0:0:0:15:0

'+15 mn' => 0:0:0:0:0:15:0

+15mn => 0:0:0:0:0:15:0

'+ 35 y 10 month 15mn' => 35:10:0:0:0:15:0

'+ 35 y 10m 15mn' => 35:10:0:0:0:15:0

'+ 35year 10:0:0:0:15:0' => __blank__

'+ 35 y -10 month 15mn' => 34:2:0:0:0:-15:0

+35:-10:0:0:0:15:0 => 34:2:0:0:0:-15:0

'+ 35 y10 month12:40' => __blank__

'+35 y 10 month 1:12:40' => __blank__

'+35x 10 month' => __blank__

'+ 35 y -10 month 1:12:40' => __blank__

1:2:3:4:5:6:7 => 1:2:3:4:5:6:7

'in 1:2:3:4:5:6:7' => __blank__

'1:2:3:4:5:6:7 ago' => __blank__

-1:2:3:4:5:6:7 => -1:2:3:4:5:6:7

-1::3:4:5:6:7 => -1:0:3:4:5:6:7

'1::3:4:5:6:7 ago' => __blank__

# Test normalization of deltas

+1:+1:+1:+1 => 0:0:0:1:1:1:1

+1:+1:+1:-1 => 0:0:0:1:1:0:59

+1:+1:-1:+1 => 0:0:0:1:0:59:1

+1:-1:+1:+1 => 0:0:0:1:0:-58:59

+1:+1:-1:-1 => 0:0:0:1:0:58:59

+1:-1:+1:-1 => 0:0:0:1:0:-59:1

+1:-1:-1:+1 => 0:0:0:1:-1:0:59

-0:1:+0:0:0:0:0 => 0:-1:0:0:0:0:0

-0:0:1:+0:-0:0:0 => 0:0:-1:0:0:0:0

0:0:0:0:9491:54:0  => 0:0:0:0:9491:54:0

0:0:0:0:9491:54:0 semi => 0:0:56:3:11:54:0

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Delta_Format';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  return Delta_Format(@_);
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");

$delta='1:2:3:4:5:6:7';
$bus="business $delta";

$tests="

$delta '%yv %Mv %wv %dv %hv %mv %sv'
   => '1 2 3 4 5 6 7'


$delta exact 4 '%yd %Md %wd %dd %hd %md %sd'
   => '1.1667 2.0000 3.5714 4.0000 5.1019 6.1167 7.0000'

$delta semi 4 '%yd %Md %wd %dd %hd %md %sd'
   => '1.1667 2.0000 3.6018 4.2126 5.1019 6.1167 7.0000'

$delta approx 4 '%yd %Md %wd %dd %hd %md %sd'
   => '1.2357 2.8284 3.6018 4.2126 5.1019 6.1167 7.0000'


'$bus' exact 4 '%yd %Md %wd %dd %hd %md %sd'
   => '1.1667 2.0000 3.0000 4.5669 5.1019 6.1167 7.0000'

'$bus' semi 4 '%yd %Md %wd %dd %hd %md %sd'
   => '1.1667 2.0000 3.9134 4.5669 5.1019 6.1167 7.0000'

'$bus' approx 4 '%yd %Md %wd %dd %hd %md %sd' =>
  '1.2417 2.9000 3.9134 4.5669 5.1019 6.1167 7.0000'


$delta exact 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 3.0 25.0 5.0 306.0 18367.0'

$delta semi 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 3.0 25.0 605.0 36306.0 2178367.0'

$delta approx 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 63.9 451.1 10831.8 649913.4 38994811.0'


'$bus' exact 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 3.0 4.0 41.0 2466.0 147967.0'

'$bus' semi 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 3.0 19.0 176.0 10566.0 633967.0'

'$bus' approx 1 '%yh %Mh %wh %dh %hh %mh %sh'
   => '1.0 14.0 63.9 323.4 2915.3 174925.1 10495514.5'


$delta exact 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.1667 14.0000 3.5714 25.0000 5.1019 306.1167 18367.0000'

$delta semi 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.1667 14.0000 3.6018 25.2126 605.1019 36306.1167 2178367.0000'

$delta approx 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.2357 14.8284 64.4755 451.3288 10831.8919 649913.5167 38994811.0000'


'$bus' exact 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.1667 14.0000 3.0000 4.5669 41.1019 2466.1167 147967.0000'

'$bus' semi 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.1667 14.0000 3.9134 19.5669 176.1019 10566.1167 633967.0000'

'$bus' approx 4 '%yt %Mt %wt %dt %ht %mt %st'
   => '1.2417 14.9000 64.7871 323.9356 2915.4207 174925.2417 10495514.5000'

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

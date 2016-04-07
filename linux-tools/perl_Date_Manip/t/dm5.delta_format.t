#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'FormatDelta';
$testdir = '';
$testdir = $t->testdir();

BEGIN {
   $Date::Manip::Backend = 'DM5';
}

use Date::Manip;

Date_Init("TZ=EST");

$tests="

1:2:3:4:5:6:7
4
'%yv %Mv %wv %dv %hv %mv %sv'
=>
'1 2 3 4 5 6 7'

1:2:3:4:5:6:7
4
'%yd %Md %wd %dd %hd %md %sd'
=>
'1.1667 2.0000 3.6018 4.2126 5.1019 6.1167 7.0000'

1:2:3:4:5:6:7
0
'%yh %Mh %wh %dh %hh %mh %sh'
=>
'1 14 3 25 605 36306 2178367'

1:2:3:4:5:6:7
4
'%yt %Mt %wt %dt %ht %mt %st'
=>
'1.1667 14.0000 3.6018 25.2126 605.1019 36306.1167 2178367.0000'

1:2:3:4:5:6:7
approx
4
'%yv %Mv %wv %dv %hv %mv %sv'
=>
'1 2 3 4 5 6 7'

1:2:3:4:5:6:7
approx
4
'%yd %Md %wd %dd %hd %md %sd'
=>
'1.2357 2.8283 3.6018 4.2126 5.1019 6.1167 7.0000'

1:2:3:4:5:6:7
approx
4
'%yh %Mh %wh %dh %hh %mh %sh'
=>
'1 14 63.875 451.125 10832 649926 38995567'

1:2:3:4:5:6:7
approx
4
'%yt %Mt %wt %dt %ht %mt %st'
=>
'1.2357 14.8283 64.4768 451.3376 10832.1019 649926.1167 38995567.0000'

";

$t->tests(func  => \&Delta_Format,
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

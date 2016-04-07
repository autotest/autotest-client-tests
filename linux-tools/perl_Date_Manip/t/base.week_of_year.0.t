#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'week_of_year (Y,W)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  if ($test[0] eq "config") {
    $dmt->config("jan1week1",$test[1]);
    $dmt->config("firstday",$test[2]);
    return 0;
  }
  @ret = $obj->week_of_year(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="
config 0 1 => 0

2006 4 => [ 2006 1 23 ]

2007 4 => [ 2007 1 22 ]

2002 4 => [ 2002 1 21 ]

2003 4 => [ 2003 1 20 ]

2004 4 => [ 2004 1 19 ]

2010 4 => [ 2010 1 25 ]

2000 4 => [ 2000 1 24 ]


config 0 7 => 0

2006 4 => [ 2006 1 22 ]

2007 4 => [ 2007 1 21 ]

2002 4 => [ 2002 1 20 ]

2003 4 => [ 2003 1 19 ]

2004 4 => [ 2004 1 25 ]

2010 4 => [ 2010 1 24 ]

2000 4 => [ 2000 1 23 ]


config 1 1 => 0

2006 4 => [ 2006 1 16 ]

2007 4 => [ 2007 1 22 ]

2002 4 => [ 2002 1 21 ]

2003 4 => [ 2003 1 20 ]

2004 4 => [ 2004 1 19 ]

2010 4 => [ 2010 1 18 ]

2000 4 => [ 2000 1 17 ]


config 1 7 => 0

2006 4 => [ 2006 1 22 ]

2007 4 => [ 2007 1 21 ]

2002 4 => [ 2002 1 20 ]

2003 4 => [ 2003 1 19 ]

2004 4 => [ 2004 1 18 ]

2010 4 => [ 2010 1 17 ]

2000 4 => [ 2000 1 16 ]

config 0 1 => 0

2007 02 => [ 2007 1 8 ]

2008 02 => [ 2008 1 7 ]

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'week1_day1';
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
  @ret = $obj->week1_day1(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="
config 0 1 => 0

2006 => [ 2006 1 2 ]

2007 => [ 2007 1 1 ]

2002 => [ 2001 12 31 ]

2003 => [ 2002 12 30 ]

2004 => [ 2003 12 29 ]

2010 => [ 2010 1 4 ]

2000 => [ 2000 1 3 ]


config 0 7 => 0

2006 => [ 2006 1 1 ]

2007 => [ 2006 12 31 ]

2002 => [ 2001 12 30 ]

2003 => [ 2002 12 29 ]

2004 => [ 2004 1 4 ]

2010 => [ 2010 1 3 ]

2000 => [ 2000 1 2 ]


config 1 1 => 0

2006 => [ 2005 12 26 ]

2007 => [ 2007 1 1 ]

2002 => [ 2001 12 31 ]

2003 => [ 2002 12 30 ]

2004 => [ 2003 12 29 ]

2010 => [ 2009 12 28 ]

2000 => [ 1999 12 27 ]


config 1 7 => 0

2006 => [ 2006 1 1 ]

2007 => [ 2006 12 31 ]

2002 => [ 2001 12 30 ]

2003 => [ 2002 12 29 ]

2004 => [ 2003 12 28 ]

2010 => [ 2009 12 27 ]

2000 => [ 1999 12 26 ]

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

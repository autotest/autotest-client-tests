#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'weeks_in_year';
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
  @ret = $obj->weeks_in_year(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="
config 0 1 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 52

2004 => 53

2010 => 52

2000 => 52


config 0 7 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 53

2004 => 52

2010 => 52

2000 => 52


config 1 1 => 0

2006 => 53

2007 => 52

2002 => 52

2003 => 52

2004 => 52

2010 => 52

2000 => 53


config 1 7 => 0

2006 => 52

2007 => 52

2002 => 52

2003 => 52

2004 => 52

2010 => 52

2000 => 53

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

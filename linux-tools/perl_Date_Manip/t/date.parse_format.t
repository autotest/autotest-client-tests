#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'parse_format';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test) = @_;
  $err = $obj->parse_format(@test);
  if ($err) {
     return $err;
  }
  $v = $obj->value();
  return $v;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-21-12:30:45,America/New_York");

$tests=q{

%Y\\.%m\\-%d
2000.12-13
   =>
   2000121300:00:00

'.*?\\[%d/%b/%Y:%T %z\\].*'
'10.11.12.13 - - [17/Aug/2009:12:33:30 -0400] "GET /favicon.ico ..."'
   =>
   2009081712:33:30

%r
'12:01:02 AM'
   =>
   2000012100:01:02

};

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

1;

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter '_ruleInfo';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');

$t->use_ok('Date::Manip::TZdata');

if ( -d "$testdir/../tzdata" ) {
  $obj = new Date::Manip::TZdata("$testdir/..");
} else {
  $t->skip_all('No tzdata directory');
}

sub test {
  (@test)=@_;
  return $obj->_ruleInfo(@test);
}

$tests="

HK stdlett 1955 => __blank__

HK savlett 1955 => S

Iran stdlett 1980 => S

Iran savlett 1980 => D

Chicago lastoff 1920 => 00:00:00

Winn lastoff 1942 => 01:00:00

US rdates 1918 =>
   1918033102:00:00
   01:00:00
   w
   D
   1918102702:00:00
   00:00:00
   w
   S

US rdates 1942 =>
   1942020902:00:00
   01:00:00
   w
   W

US rdates 1945 =>
   1945081423:00:00
   01:00:00
   u
   P
   1945093002:00:00
   00:00:00
   w
   S

US rdates 2010 =>
   2010031402:00:00
   01:00:00
   w
   D
   2010110702:00:00
   00:00:00
   w
   S

RussiaAsia rdates 1990 =>
   1990032502:00:00
   01:00:00
   s
   S
   1990093002:00:00
   00:00:00
   s
   __blank__

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

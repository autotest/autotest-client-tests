#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'define_abbrev';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($abbrev,@zone)=@_;
  $obj->define_abbrev("reset");
  $obj->define_abbrev($abbrev,@zone);
  return $obj->zone($abbrev);
}

$obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

$tests="

BRT reset =>
   America/Araguaina
   America/Bahia
   America/Belem
   America/Fortaleza
   America/Maceio
   America/Recife
   America/Sao_Paulo
   America/Santarem

BRT
America/Sao_Paulo
America/Santarem
America/Araguaina
America/Bahia
   =>
   America/Sao_Paulo
   America/Santarem
   America/Araguaina
   America/Bahia
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

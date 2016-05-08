#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'set (Printable=1)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $err = $obj->set(@test);
  if ($err) {
     return $obj->err();
  } else {
     my $ret = $obj->value();
     return $ret;
  }
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config("printable",1);

$tests=join('',<DATA>);

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

1;
__DATA__

date [ 1996 1 1 12 0 0 ]  => 19960101120000

date [ 1996 13 1 12 0 0 ] => '[set] Invalid date argument'

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

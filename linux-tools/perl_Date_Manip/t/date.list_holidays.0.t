#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'list_holidays (simple)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @date = $obj->list_holidays(@test);
  @ret  = ();
  foreach my $date (@date) {
     my $val = $date->value();
     push(@ret,$val);
  }
  return @ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-01-00:00:00,America/New_York");
$obj->config("ConfigFile","$testdir/Manip.cnf");

$tests="

   =>
   2000011700:00:00
   2000022100:00:00
   2000052900:00:00
   2000070400:00:00
   2000090400:00:00
   2000100900:00:00
   2000111000:00:00
   2000112300:00:00
   2000112400:00:00
   2000122500:00:00

1999
   =>
   1999010100:00:00
   1999011800:00:00
   1999021500:00:00
   1999053100:00:00
   1999060200:00:00
   1999070500:00:00
   1999090600:00:00
   1999101100:00:00
   1999111100:00:00
   1999112500:00:00
   1999112600:00:00
   1999122400:00:00
   1999123100:00:00

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

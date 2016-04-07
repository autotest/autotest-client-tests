#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'list_events(format=dates)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($date,$date2)=@_;
  $obj->err(1);
  $obj->parse($date);
  $obj2->parse($date2);

  @d = $obj->list_events($obj2,"dates");
  @ret = ();
  foreach $d (@d) {
     ($d,@name) = @$d;
     $v = $d->value();
     push(@ret,$v,@name);
  }
  return @ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","now,America/New_York");
$obj->config("ConfigFile","$testdir/Events.cnf");
$obj2 = $obj->new_date();

$tests ="

'2000-01-31 12:00:00'
'2000-02-04 00:00:00'
   =>
   2000013112:00:00
   2000020100:00:00
   Event01
   Event03
   2000020112:00:00
   Event01
   Event02
   Event03
   Event04
   2000020113:00:00
   Event01
   Event03
   2000020200:00:00
   2000020313:00:00
   Event05
   2000020314:00:00

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

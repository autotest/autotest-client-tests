#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (date,delta,romanian)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;

  $err = $obj1->parse(shift(@test));
  return $$obj1{"err"}  if ($err);
  $err = $obj2->parse(shift(@test));
  return $$obj2{"err"}  if ($err);

  my $obj3 = $obj1->calc($obj2,@test);
  return   if (! defined $obj3);
  $ret = $obj3->value();
  return $ret;
}

$obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York",
              "language","romanian");
$obj2 = $obj1->new_delta();

$tests="

'Mie Febr 7 1996 8:00' +1:1:1:1 => 1996020809:01:01

'Mie Nov 20 1996 amiaza' +0:5:0:0 => 1996112017:00:00

'Mie Nov 20 1996 amiaza' +0:13:0:0 => 1996112101:00:00

'Mie Nov 20 1996 amiaza' +3:2:0:0 => 1996112314:00:00

'Mie Nov 20 1996 amiaza' -3:2:0:0 => 1996111710:00:00

'Mie Nov 20 1996 amiaza' +3:13:0:0 => 1996112401:00:00

'Mie Nov 20 1996 amiaza' +6:2:0:0 => 1996112614:00:00

'Dec 31 1996 amiaza' +1:2:0:0 => 1997010114:00:00

'Ian 31 1997 23:59:59' '+ 1 sec' => 1997020100:00:00

'Mie Feb 7 1996 8:00' +1:1:1:1 => 1996020809:01:01

'Mie Nov 20 1996 amiaza' +0:2:0:0 => 1996112014:00:00

'Mie Nov 20 1996 amiaza' +3:7:0:0 => 1996112319:00:00

'Dec 30 1996 amiaza' +1:2:0:0 => 1996123114:00:00

'Mart 31 1997 23:59:59' '+ 1 sec' => 1997040100:00:00

'Mie Nov 20 1996 amiaza' +0:0:1:0:0:0:0 => 1996112712:00:00

'Mie Nov 20 1996 19:00' '5 ore' => 1996112100:00:00

'Mie Nov 20 1996 12:00' +0:2:0:0 => 1996112014:00:00

'Mie Nov 20 1996 12:00' '3 zile 2 h' => 1996112314:00:00

'Mie Nov 20 1996 12:00' 'in urma 3 zile 2 ore' => 1996111710:00:00

'Mie Nov 20 1996 12:00' '5 ore' => 1996112017:00:00

'Mie Nov 20 1996 12:00' '3 zile 2 h' => 1996112314:00:00

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

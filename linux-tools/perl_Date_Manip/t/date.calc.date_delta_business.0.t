#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (date,delta,business 08:00-17:00)';
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
  if ($$obj3{'err'}) {
     return $$obj3{'err'};
  }
  $ret = $obj3->value();
  return $ret;
}

$obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj2 = $obj1->new_delta();

$tests="

'Wed Nov 20 1996 noon' 'business +0:5:0:0' => 1996112108:00:00

'Wed Nov 20 1996 noon' 'business -0:5:0:0' 1 => 1996112108:00:00

'Wed Nov 20 1996 noon' 'business +0:2:0:0' => 1996112014:00:00

'Wed Nov 20 1996 noon' 'business -0:2:0:0' 1 => 1996112014:00:00

'Wed Nov 20 1996 noon' 'business +3:2:0:0' => 1996112514:00:00

'Wed Nov 20 1996 noon' 'business 3:2:0:0' 1 => 1996111510:00:00

'Wed Nov 20 1996 noon' 'business -3:2:0:0' => 1996111510:00:00

'Wed Nov 20 1996 noon' 'business +3:7:0:0' => 1996112610:00:00

'Wed Nov 20 1996 noon' 'business +6:2:0:0' => 1996112814:00:00

'Dec 31 1996 noon' 'business +1:2:0:0' => 1997010114:00:00

'Dec 30 1996 noon' 'business +1:2:0:0' => 1996123114:00:00

'Mar 31 1997 16:59:59' 'business + 1 sec' => 1997040108:00:00

'Wed Nov 20 1996 noon' 'business +0:0:1:0:0:0:0' => 1996112712:00:00

2002120600:00:00 '- business 4 hours' => 2002120513:00:00

2002120600:00:01 '- business 4 hours' => 2002120513:00:00

2002120523:59:59 '- business 4 hours' => 2002120513:00:00

2002120602:00:00 '- business 4 hours' => 2002120513:00:00

2002120609:00:00 '- business 4 hours' => 2002120514:00:00

2002120609:00:10 '- business 4 hours' => 2002120514:00:10

2002120611:00:00 '- business 4 hours' => 2002120516:00:00

2002120612:00:00 '- business 4 hours' => 2002120608:00:00

2002120512:00:00 '+ business 4 hours' => 2002120516:00:00

2002120514:00:00 '+ business 4 hours' => 2002120609:00:00

2002120522:00:00 '+ business 4 hours' => 2002120612:00:00

2002120523:59:59 '+ business 4 hours' => 2002120612:00:00

2002120602:00:00 '+ business 4 hours' => 2002120612:00:00

2002120609:00:00 '+ business 4 hours' => 2002120613:00:00

1998010500:00:00 '0:1:1:0:0:0:0 business' 0 => 1998021208:00:00

1998010500:00:00 '0:1:1:0:0:0:0 business' 1 => 1997112808:00:00

1998010500:00:00 '0:1:1:0:0:0:0 business' 2 => '[calc] Unable to perform calculation'

1998010400:00:00 '0:1:1:0:0:0:0 business' 0 => 1998021108:00:00

1998010400:00:00 '0:1:1:0:0:0:0 business' 1 => 1997112708:00:00

1998010400:00:00 '0:1:1:0:0:0:0 business' 2 => '[calc] Unable to perform calculation'

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

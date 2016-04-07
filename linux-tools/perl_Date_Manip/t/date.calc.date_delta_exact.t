#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (date,exact delta)';
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
  $abb = $$obj3{'data'}{'abb'};
  return ($ret,$abb);
}

$obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj2 = $obj1->new_delta();

$tests="

2011-12-11-12:00:00    +24:0:0      => 2011121212:00:00 EST

2011-12-11-12:00:00    +97:1:30     => 2011121513:01:30 EST

2011-04-03-12:00:00    +2018:2:45   => 2011062614:02:45 EDT

1997-01-31-23:59:59    '+ 1 sec'    => 1997020100:00:00 EST

2005-02-15-13:59:11    -10h         => 2005021503:59:11 EST

2005-02-15-13:59:11    '-10h +0s'   => 2005021503:59:11 EST

2001-02-03-04:05:06    '+ 2 hours'  => 2001020306:05:06 EST

2001-02-03-04:05:06    '- 2 hours'  => 2001020302:05:06 EST

2001-02-03-04:05:06    '+ -2 hours' => '[parse] Invalid delta string'


#
# Spring forward: 2011-03-13 02:00 EST -> 2011-03-13 03:00 EDT
#

2011-03-13-01:59:59         +1           => 2011031303:00:00 EDT

2011-03-12-12:00:00         +24:0:0      => 2011031313:00:00 EDT

#
# Fall back: 2011-11-06 02:00 EDT -> 2011-11-06 01:00 EST
#

'2011-11-06 01:59:59 EDT'   +1           => 2011110601:00:00 EST

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

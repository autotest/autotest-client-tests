#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'calc (date,date,semi)';
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
  push(@test,"semi");

  my $obj3 = $obj1->calc($obj2,@test);
  return   if (! defined $obj3);
  $ret = $obj3->value();
  return $ret;
}

$obj1 = new Date::Manip::Date;
$obj1->config("forcedate","now,America/New_York");
$obj2 = $obj1->new_date();

$tests="

1996-01-01-12:00:00  1996-01-01-14:30:30    => 0:0:0:0:2:30:30

1996-01-01-12:00:00  1996-01-01-14:30:30 1  => 0:0:0:0:-2:30:30

1996-01-01-14:30:30  1996-01-01-12:00:00    => 0:0:0:0:-2:30:30

1996-01-01-12:00:00  1996-01-02-14:30:30    => 0:0:0:1:2:30:30

1996-01-01-12:00:00  1996-01-02-14:30:30 1  => 0:0:0:-1:2:30:30

1996-01-01-12:00:00  1996-01-02-14:30:30 2  => 0:0:0:-1:2:30:30

1996-01-02-14:30:30  1996-01-01-12:00:00    => 0:0:0:-1:2:30:30

1996-01-01-12:00:00  1996-01-02-10:30:30    => 0:0:0:1:-1:29:30

1996-01-02-10:30:30  1996-01-01-12:00:00    => 0:0:0:-1:+1:29:30

1996-01-01-12:00:00  1997-01-02-10:30:30    => 0:0:52:3:-1:29:30

1996-01-01-12:00:00  1997-01-02-10:30:30 1  => 0:0:-52:3:+1:29:30

1996-01-01-12:00:00  1997-01-02-10:30:30 2  => 0:0:-52:3:+1:29:30

1997-01-02-10:30:30  1996-01-01-12:00:00    => 0:0:-52:3:+1:29:30

1997-01-01-00:00:01  1997-02-01-00:00:00    => 0:0:4:3:0:0:-1

1997-01-01-00:00:01  1997-03-01-00:00:00    => 0:0:8:3:0:0:-1

1997-01-01-00:00:01  1998-03-01-00:00:00    => 0:0:60:4:0:0:-1

2008-01-01-12:00:00  2008-06-01-12:00:00    => 0:0:21:5:0:0:0

# Timezones

'1996010112:00:00 CST'  '1996010214:30:30 CST'    => 0:0:0:1:2:30:30

'1996010112:00:00 CST'  '1996010215:30:30 EST'    => 0:0:0:1:2:30:30

'2008010112:00:00 CST'  '2008060112:00:00 CDT'    => 0:0:21:5:0:0:0

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'Event_List';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  $ref = Events_List(@_);

  if (ref($ref) eq "ARRAY") {
     @ret = ();
     @tmp = @$ref;
     while (@tmp) {
        $v = shift(@tmp);
        if (ref($v) eq "ARRAY") {
           unshift(@tmp,@$v);
        } else {
           push(@ret,$v);
        }
     }
     return @ret;
  }

  if (ref($ref) eq "HASH") {
     @ret = ();
     foreach $key (sort keys %$ref) {
        push(@ret,$key,$$ref{$key});
     }
     return @ret;
  }

  return ();
}

Date_Init("ForceDate=1997-03-08-12:30:00,America/New_York");
Date_Init("ConfigFile=$testdir/OldEvents.cnf");

$tests ="

2000-02-01 =>
   2000020100:00:00
   Event1
   Winter

2000-04-01 =>
   2000040100:00:00
   Spring

2000-04-01 0 =>
   2000040100:00:00
   Spring
   2000040112:00:00
   Event3
   Spring
   2000040113:00:00
   Spring

'2000-04-01 12:30' =>
   2000040112:30:00
   Event3
   Spring

'2000-04-01 13:30' =>
   2000040113:30:00
   Spring

2000-03-15 2000-04-10 =>
   2000031500:00:00
   Winter
   2000032200:00:00
   Spring
   2000040112:00:00
   Event3
   Spring
   2000040113:00:00
   Spring

2000-03-15 2000-04-10 1 =>
   Event3
   0:0:0:0:1:0:0
   Spring
   0:0:0:0:455:0:0
   Winter
   0:0:0:0:168:0:0

2000-03-15 2000-04-10 2 =>
   Event3+Spring
   0:0:0:0:1:0:0
   Spring
   0:0:0:0:454:0:0
   Winter
   0:0:0:0:168:0:0

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

#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'frequency';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  $err = $obj->frequency(@test);
  if ($err) {
     return $obj->err();
  } else {
     @ret = @{ $$obj{"data"}{"interval"} };
     push(@ret,"*");
     foreach my $v (@{ $$obj{"data"}{"rtime"} }) {
        $str = "";
        foreach my $v2 (@$v) {
           $str .= ","  if ($str ne "");
           if (ref($v2)) {
              ($x,$y) = @$v2;
              $str .= "$x-$y";
           } else {
              $str .= "$v2";
           }
        }
        push(@ret,$str);
     }
     return @ret;
  }
}

$obj = new Date::Manip::Recur;
$obj->config("forcedate","2000-01-21-00:00:00,America/New_York");

$tests="

1:2:3:4:5:6:7 => 1 2 3 4 5 6 7 *

1:2:3:4:5:6
   => 
   '[frequency] Invalid frequency string'

+1:2:3:4:5:6:7
   => 
   '[frequency] Invalid frequency string'

1:2:0*0:5:6:7 => 1 2 * 0 0 5 6 7

0:0:0*4:5:6:7 => 0 0 1 * 4 5 6 7

1:2:3*--4:5:6:7
   => 
   '[frequency] Invalid rtime string'

1:2:3*4-3:5:6:7
   => 
   '[frequency] Invalid rtime range string'

1:2:0:0*5,8:6:7 => 1 2 0 0 * 5,8 6 7

1:2:0:0*5-8,11:6:7 => 1 2 0 0 * 5,6,7,8,11 6 7

1:2:0*0:5-8,11:6:7 => 1 2 * 0 0 5,6,7,8,11 6 7

1:2:0:0*5-8,11:-1:7
   => 
   '[frequency] Negative values allowed for day/week'

1:2:0:0*5-8,11:-3--1:7
   => 
   '[frequency] Negative values allowed for day/week'

1:2*-1--3:0:5-8,11:1:7
   => 
   '[frequency] Invalid rtime range string'

1:2*-3--1:0:5-8,11:1:7 => 1 2 * -3,-2,-1 0 5,6,7,8,11 1 7

1:2*2--2:0:5-8,11:1:7 => 1 2 * 2--2 0 5,6,7,8,11 1 7

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

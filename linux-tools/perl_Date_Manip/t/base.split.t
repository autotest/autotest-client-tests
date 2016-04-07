#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'split';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->split(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

date 1996010112:00:00    => [ 1996 1 1 12 0 0 ]

date 1996-01-01-12:00:00 => [ 1996 1 1 12 0 0 ]

############

offset 10             => [ 10 0 0 ]

offset 10:70          => __undef__

offset 10:-70         => __undef__

offset 10:-70:130:+90 => __undef__

offset 5              => [ 5 0 0 ]

offset -5             => [ -5 0 0 ]

offset 5:30           => [ 5 30 0 ]

offset -5:30          => [ -5 -30 0 ]

offset 5:30:45        => [ 5 30 45 ]

offset -5:30:45       => [ -5 -30 -45 ]

############

hms 10                => [ 10 0 0 ]

hms 10:70             => __undef__

hms 10:-70            => __undef__

hms 10:-70:130:+90    => __undef__

hms 0:0:5             => __undef__

hms 0:00:05           => [ 0 0 5 ]

hms 0:05:30           => [ 0 5 30 ]

hms 5:30:45           => [ 5 30 45 ]

############

time 10:-70           => [ 0 8 50 ]

time 10:-70:130:+90   => __undef__

time 10:70            => [ 0 11 10 ]

time +0:0:5           => [ 0 0 5 ]

time +0:5:30          => [ 0 5 30 ]

time +5:30:45         => [ 5 30 45 ]

time -0:0:5           => [ 0 0 -5 ]

time -0:5:30          => [ 0 -5 -30 ]

time -5:30:45         => [ -5 -30 -45 ]

time 10               => [ 0 0 10 ]

############

delta 10                     => [ 0 0 0 0 0 0 10 ]

delta 10:-70                 => [ 0 0 0 0 0 8 50 ]

delta 10:-70:130:+90         => [ 0 0 1 3 -72 -8 -30 ]

delta 10:70                  => [ 0 0 0 0 0 11 10 ]

delta -1:13:2:10:+70:-130:90 => [ -2 -1 -3 -3 67 48 30 ]

delta 1:13:2:10:-70:130:+90  => [ 2 1 3 3 -72 -8 -30 ]

delta 1::                    => [ 0 0 0 0 1 0 0 ]

############

business 10:-70                 => [ 0 0 0 0 0 8 50 ]

business 10:-70:130:90          => [ 0 0 0 1 8 48 30 ]

business 10:70                  => [ 0 0 0 0 0 11 10 ]

business -1:13:2:10:+25:-130:90 => [ -2 -1 -2 -7 -4 -11 -30 ]

business 10                     => [ 0 0 0 0 0 0 10 ]

business 1:13:2:10:-25:130:+90  => [ 2 1 2 6 8 51 30 ]

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

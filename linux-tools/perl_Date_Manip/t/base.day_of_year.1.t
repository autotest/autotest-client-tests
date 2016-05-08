#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'day_of_year (Y/M/D/H/Mn/S)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->day_of_year(@test);
  foreach my $ret (@ret) {
    if (ref($ret)) {
       foreach my $val (@$ret) {
          if ($val =~ /\./) {
             $val = sprintf("%.2f",$val);
          }
       }

    } elsif ($ret =~ /\./) {
      $ret = sprintf("%.2f",$ret);
    }
  }
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");

$tests="

1997 10       => [ 1997 1 10 ]

[ 1997 1 10 ] => 10


1997 10.5            => [ 1997 1 10 12 0 0 ]

[ 1997 1 10 12 0 0 ] => 10.50


1997 10.510763888888889   => [ 1997 1 10 12 15 30.00 ]

[ 1997 1 10 12 15 30.00 ] => 10.51

1997 10.510770138888889   => [ 1997 1 10 12 15 30.54 ]

[ 1997 1 10 12 15 30.54 ] => 10.51


2000 31    => [ 2000 1 31 ]

2000 31.5  => [ 2000 1 31 12 0 0 ]

2000 32    => [ 2000 2 1 ]

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

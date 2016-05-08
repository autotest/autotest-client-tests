#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter '_fix_year (50)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @ret = $obj->_fix_year(@test);
  return @ret;
}

$dmt = new Date::Manip::TZ;
$obj = $dmt->base();
$dmt->config("forcedate","now,America/New_York");
$obj->_method("50");

sub _y {
  my($yyyy) = @_;
  $yyyy     =~ /^..(..)/;
  my $yy    = $1;
  return($yyyy,$yy);
}

$y  = ( localtime(time) )[5];
$y += 1900;

($yyyy,$yy)       = _y($y);

($yyyyM05,$yyM05) = _y($y-5);
($yyyyP05,$yyP05) = _y($y+5);

($yyyyM49,$yyM49) = _y($y-49);
($yyyyM50,$yyM50) = _y($y-50);
($yyyyM51,$yyM51) = _y($y-51);  $yyyyM51 += 100;

($yyyyP48,$yyP48) = _y($y+48);
($yyyyP49,$yyP49) = _y($y+49);
($yyyyP50,$yyP50) = _y($y+50);  $yyyyP50 -= 100;

$tests="

$yy     => $yyyy

$yyM05  => $yyyyM05

$yyP05  => $yyyyP05

$yyM49  => $yyyyM49

$yyM50  => $yyyyM50

$yyM51  => $yyyyM51

$yyP48  => $yyyyP48

$yyP49  => $yyyyP49

$yyP50  => $yyyyP50

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

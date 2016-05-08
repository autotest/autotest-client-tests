#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'convert';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  ($delta,$to)=@_;
  $obj->parse($delta);
  $obj->convert($to);
  @val = $obj->value();
  return (@val,$$obj{"data"}{"business"});
}

$obj = new Date::Manip::Delta;
$obj->config("forcedate","now,America/New_York");

$tests="

'0:0:0:0:2:30:0'                exact   => 0 0 0 0 2 30 0 0

'0:0:0:0:2:30:0'                semi    => 0 0 0 0 2 30 0 0

'0:0:0:0:2:30:0'                approx  => 0 0 0 0 2 30 0 0

#

'0:0:0:0:0:0:60'                exact   => 0 0 0 0 0 1 0 0

'0:0:0:0:0:0:60'                semi    => 0 0 0 0 0 1 0 0

'0:0:0:0:0:0:60'                approx  => 0 0 0 0 0 1 0 0

#

'0:0:0:0:0:0:3600'              exact   => 0 0 0 0 1 0 0 0

'0:0:0:0:0:0:3600'              semi    => 0 0 0 0 1 0 0 0

'0:0:0:0:0:0:3600'              approx  => 0 0 0 0 1 0 0 0

#

'0:0:0:0:0:0:86400'             exact   => 0 0 0 0 24 0 0 0

'0:0:0:0:0:0:86400'             semi    => 0 0 0 1 0 0 0 0

'0:0:0:0:0:0:86400'             approx  => 0 0 0 1 0 0 0 0

#

'0:0:0:0:0:0:604800'            exact   => 0 0 0 0 168 0 0 0

'0:0:0:0:0:0:604800'            semi    => 0 0 1 0 0 0 0 0

'0:0:0:0:0:0:604800'            approx  => 0 0 1 0 0 0 0 0

#

'0:0:0:0:0:0:31556952'          exact   => 0 0 0 0 8765 49 12 0

'0:0:0:0:0:0:31556952'          semi    => 0 0 52 1 5 49 12 0

'0:0:0:0:0:0:31556952'          approx  => 1 0 0 0 0 0 0 0

#

'0:0:0:1:0:0:0'                 exact   => 0 0 0 0 24 0 0 0

'0:0:0:1:0:0:0'                 semi    => 0 0 0 1 0 0 0 0

'0:0:0:1:0:0:0'                 approx  => 0 0 0 1 0 0 0 0

#

'0:0:0:367:0:0:0'               exact   => 0 0 0 0 8808 0 0 0

'0:0:0:367:0:0:0'               semi    => 0 0 52 3 0 0 0 0

'0:0:0:367:0:0:0'               approx  => 1 0 0 1 18 10 48 0

#

'0:1:0:0:0:0:0'                 exact   => 0 0 0 0 730 29 6 0

'0:1:0:0:0:0:0'                 semi    => 0 0 4 2 10 29 6 0

'0:1:0:0:0:0:0'                 approx  => 0 1 0 0 0 0 0 0

#

'0:0:0:0:2:30:0 business'       exact   => 0 0 0 0 2 30 0 1

'0:0:0:0:2:30:0 business'       semi    => 0 0 0 0 2 30 0 1

'0:0:0:0:2:30:0 business'       approx  => 0 0 0 0 2 30 0 1

#

'0:0:0:0:0:0:60 business'       exact   => 0 0 0 0 0 1 0 1

'0:0:0:0:0:0:60 business'       semi    => 0 0 0 0 0 1 0 1

'0:0:0:0:0:0:60 business'       approx  => 0 0 0 0 0 1 0 1

#

'0:0:0:0:0:0:3600 business'     exact   => 0 0 0 0 1 0 0 1

'0:0:0:0:0:0:3600 business'     semi    => 0 0 0 0 1 0 0 1

'0:0:0:0:0:0:3600 business'     approx  => 0 0 0 0 1 0 0 1

#

'0:0:0:0:0:0:32400 business'    exact   => 0 0 0 1 0 0 0 1

'0:0:0:0:0:0:32400 business'    semi    => 0 0 0 1 0 0 0 1

'0:0:0:0:0:0:32400 business'    approx  => 0 0 0 1 0 0 0 1

#

'0:0:0:0:0:0:162000 business'   exact   => 0 0 0 5 0 0 0 1

'0:0:0:0:0:0:162000 business'   semi    => 0 0 1 0 0 0 0 1

'0:0:0:0:0:0:162000 business'   approx  => 0 0 1 0 0 0 0 1

#

'0:0:0:0:0:0:8452755 business'  exact   => 0 0 0 260 7 59 15 1

'0:0:0:0:0:0:8452755 business'  semi    => 0 0 52 0 7 59 15 1

'0:0:0:0:0:0:8452755 business'  approx  => 1 0 0 0 0 0 0 1

#

'0:0:0:1:0:0:0 business'        exact   => 0 0 0 1 0 0 0 1

'0:0:0:1:0:0:0 business'        semi    => 0 0 0 1 0 0 0 1

'0:0:0:1:0:0:0 business'        approx  => 0 0 0 1 0 0 0 1

#

'0:0:1:0:0:0:0 business'        exact   => 0 0 0 5 0 0 0 1

'0:0:1:0:0:0:0 business'        semi    => 0 0 1 0 0 0 0 1

'0:0:1:0:0:0:0 business'        approx  => 0 0 1 0 0 0 0 1

#

'0:0:53:0:0:0:0 business'       exact   => 0 0 0 265 0 0 0 1

'0:0:53:0:0:0:0 business'       semi    => 0 0 53 0 0 0 0 1

'0:0:53:0:0:0:0 business'       approx  => 1 0 0 4 1 0 45 1

#

'0:1:0:0:0:0:0 business'        exact   => 0 0 0 21 6 39 56 1

'0:1:0:0:0:0:0 business'        semi    => 0 0 4 1 6 39 56 1

'0:1:0:0:0:0:0 business'        approx  => 0 1 0 0 0 0 0 1

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

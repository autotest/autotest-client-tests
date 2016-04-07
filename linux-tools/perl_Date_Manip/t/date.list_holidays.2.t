#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'list_holidays (New Years 2)';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');


sub test {
  (@test)=@_;
  @date = $obj->list_holidays(@test);
  @ret  = ();
  foreach my $date (@date) {
     my $val = $date->value();
     push(@ret,$val);
  }
  return @ret;
}

$obj = new Date::Manip::Date;
$obj->config("forcedate","2000-01-01-00:00:00,America/New_York");
$obj->config("ConfigFile","$testdir/Holidays.2.cnf");

$tests="

# Test New Year's Day definition:
# Test Y, Y-1 with Y having Jan 1 on Mon (1990)
# Test Y, Y-1 with Y having Jan 1 on Tue (1980)
# Test Y, Y-1 with Y having Jan 1 on Fri (1999)
# Test Y, Y-1 with Y having Jan 1 on Sat (2000)
# Test Y, Y-1 with Y having Jan 1 on Sun (1989)

# Test Christmas, Boxing Day definitions:
# Christmas on Sun (1988)
# Christmas on Mon (2000)
# Christmas on Fri (1998)
# Christmas on Sat (1999)

2000
   =>
   2000122500:00:00
   2000122600:00:00

1999
   =>
   1999010100:00:00
   1999122700:00:00
   1999122800:00:00
   1999123100:00:00

1998
   =>
   1998010100:00:00
   1998122500:00:00
   1998122800:00:00

1990
   =>
   1990010100:00:00
   1990122500:00:00
   1990122600:00:00

1989
   =>
   1989010200:00:00
   1989122500:00:00
   1989122600:00:00

1988
   =>
   1988010100:00:00
   1988122600:00:00
   1988122700:00:00

1980
   =>
   1980010100:00:00
   1980122500:00:00
   1980122600:00:00

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

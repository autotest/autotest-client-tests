#!/usr/bin/perl -w

use Test::Inter;
$t = new Test::Inter 'zone';
$testdir = '';
$testdir = $t->testdir();

use Date::Manip;
if (DateManipVersion() >= 6.00) {
   $t->feature("DM6",1);
}

$t->skip_all('Date::Manip 6.xx required','DM6');

sub test {
  (@test)=@_;
  return $obj->zone(@test);
}

$obj = new Date::Manip::TZ;
$obj->config("forcedate","now,America/New_York");

$tests="

#
# Zone only tests
#

America/New_York    => America/New_York

AAAmerica/New_York  => __undef__

america/new_york    => America/New_York

est5edt             => America/New_York

us/eastern          => America/New_York

#
# Abbrev only tests
#

ywt =>
   America/Whitehorse
   America/Dawson
   America/Yakutat

#
# Offset tests
#

+06:30:00 stdonly =>
   Indian/Cocos
   Asia/Colombo
   Asia/Dhaka
   Asia/Kolkata
   Asia/Rangoon

+06:30:00 dstonly =>
   Asia/Colombo
   Asia/Karachi
   Asia/Kolkata

+06:30:00 std =>
   Indian/Cocos
   Asia/Colombo
   Asia/Dhaka
   Asia/Kolkata
   Asia/Rangoon
   Asia/Karachi

+06:30:00 dst =>
   Asia/Colombo
   Asia/Karachi
   Asia/Kolkata
   Indian/Cocos
   Asia/Dhaka
   Asia/Rangoon

#
# Abbrev/offset tests
#

-05:00:00 EDT =>

-05:00:00 CLT => America/Santiago

#
# Mixed data
#

=>
   America/New_York

std
   =>
   America/New_York

dstonly
   =>
   America/New_York

-2
stdonly
   =>
   Atlantic/South_Georgia
   Etc/GMT-2
   America/Noronha
   America/Scoresbysund
   Atlantic/Cape_Verde
   Atlantic/Azores
   B

-02:00
stdonly
   =>
   Atlantic/South_Georgia
   Etc/GMT-2
   America/Noronha
   America/Scoresbysund
   Atlantic/Cape_Verde
   Atlantic/Azores
   B

[ 2001 01 01 00 00 00 ]                   => America/New_York

[ 2001 01 01 00 00 00 ] ABC               => __undef__

[ 2001 01 01 00 00 00 ] 9:50:0x           => __undef__

[ 2001 01 01 00 00 00 ] 9:50:00           => __undef__

[ 2001 01 01 00 00 00 ] -12:00:00 dstonly =>

[ 2001 01 01 00 00 00 ] -14:17:00         =>

[ 1800 01 01 00 00 00 ] -14:17:00 MPT     =>

[ 1910 01 01 00 00 00 ] 09:00:00  MPT     => Pacific/Saipan

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

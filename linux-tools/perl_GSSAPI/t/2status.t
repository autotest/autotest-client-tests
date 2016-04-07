#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;

use GSSAPI qw(:all);
use Test::More tests => 9;



ok( GSSAPI::Status::GSS_ERROR(GSS_S_COMPLETE) == 0,
   'GSSAPI::Status::GSS_ERROR(GSS_S_COMPLETE) == 0' );

ok( GSSAPI::Status::GSS_ERROR(GSS_S_BAD_SIG) == 1,
    'GSSAPI::Status::GSS_ERROR(GSS_S_BAD_SIG) == 1' );

my $status = GSSAPI::Status->new(GSS_S_COMPLETE, 0);

ok(ref $status eq "GSSAPI::Status", 'created GSSAPI::Status object');

ok($status->major == GSS_S_COMPLETE, '$status->major == GSS_S_COMPLETE');
ok($status->minor == 0, '$status->minor == 0');
ok($status, '$status');

my @string;
ok(@string = $status->generic_message(),
             '$status->generic_message(): ' . join '', @string);
ok(@string = $status->specific_message(),
             '$status->specific_message(): ' . join '', @string);

my $okay = 1;
foreach (1 .. 1000) {
	my($maj, $min);
	$maj = int(rand(0xffffffff));
	$min = int(rand(0xffffffff));

	$status = GSSAPI::Status->new($maj, $min);

	$status->major == $maj && $status->minor == $min
			or $okay = 0, last;
}
ok($okay, 'GSSAPI::Status->new($maj, $min) with random values');
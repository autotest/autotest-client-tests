#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;
use Test::More tests => 6;

BEGIN {
    use_ok('GSSAPI');
}

my($name);

my $status = GSSAPI::Name->import( $name, 'chpasswd@mars.gac.edu' );

SKIP: {
    unless ($status->major == GSS_S_COMPLETE  ) {
         #
         # As an anwer to FAIL 413320
         # <http://www.nntp.perl.org/group/perl.cpan.testers/2007/02/msg413320.html>
         # we always printout why the GSSAPI call failed
         # to decide between general Kerberos (configuration)
         # problems on the machine that runs the test and
         # problems of the permodule itself.
         #
         skip( '->import() failed ' . $status,  5 );
    }
    my ( $name2, $same );
    ok( $status , q{ GSSAPI::Name->import( $name, 'chpasswd@mars.gac.edu' } );
    ok( ref $name eq "GSSAPI::Name",  'ref $name eq "GSSAPI::Name"');
    $status = $name->duplicate($name2);
    ok( $status->major == GSS_S_COMPLETE, '$name->duplicate($name2) ' . $status );
    $status = $name->compare($name2, $same);
    ok($status->major == GSS_S_COMPLETE, '$name->compare($name2, $same) ' . $status );
    eval {
        $status = $name->compare($name2, 0);
    };
    ok( $@ =~ /Modification of a read-only value/ , 'Modification of a read-only value');
}
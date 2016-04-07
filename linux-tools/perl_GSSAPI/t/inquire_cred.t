#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;

use GSSAPI qw(:all);
use Test::More tests => 6;


#
#   GSSAPI::Cred
#

    my($cred1, $time, $name );
    my $wanted_cred_usage = GSS_C_INITIATE;

    my $oidset;

    my $status = GSSAPI::Cred::acquire_cred(undef, 120, undef, $wanted_cred_usage,
                $cred1, $oidset, $time);

my $credusage_names = {

    GSS_C_INITIATE + 0 => 'GSS_C_INITIATE',
    GSS_C_ACCEPT   + 0 => 'GSS_C_ACCEPT',
    GSS_C_BOTH     + 0 => 'GSS_C_BOTH',

};

SKIP: {
    if ( $status->major != GSS_S_COMPLETE ) {
        diag( "\n\nNo error: acquire_cred() failed, maybe because you have to run kinit first.\n",
              "Errormessage from your GSSAPI-implementation is: \n\n" . qq{"$status"},
              "\nrun kinit to get a TGT and retry this test (just skipping now).\n\n");
        skip( 'This tests only work if user has run kinit succesfully' , 6 );
    }
    ok($status, "GSSAPI::Cred::acquire_cred, wanted_cred_usage $wanted_cred_usage");
    ok(ref $cred1 eq "GSSAPI::Cred");
    ok(ref $oidset eq "GSSAPI::OID::Set");

    my($lifetime, $cred_usage);
    $status = $cred1->inquire_cred($name, $lifetime, $cred_usage, $oidset);



    ok( $status, '$cred1->inquire_cred($name, $lifetime, $cred_usage, $oidset' );
    if ( $lifetime == -1 ) {
       diag('The returned TGT lifetime is -1 (Heimdal 1.0.x returns -1 in case of ivalid TGT)');
       diag('To get full test-coverage please run kinit to get a valid TGT and restart this test.');
       skip( '$lifetime == -1' , 2 );
    }
    {
        my $display;
        my $status = $name->display($display);
        if ( $status->major == GSS_S_COMPLETE ) {
            diag("inquire_cred()    name:\t'$display'");
        }
    }
    diag("inquire_cred()    lifetime:\t$lifetime seconds");
    diag("inquire_cred()    credusage:\t $cred_usage (" . $credusage_names->{$cred_usage} . ')' );

    ok(ref $oidset eq "GSSAPI::OID::Set");

    #
    # currently heimdal 1.3.2 fails the next test - please let me know
    # if you have any ideas what is going wrong - as far as I can see
    # this version of Heimal behaves strange and returns 'ACCEPT' if INITIATE
    # is requested :-/
    #
    ok(
          ( $cred_usage == $wanted_cred_usage or $cred_usage == GSS_C_BOTH ) ,
          sprintf('expected cred usage (wanted %s, got %s)', map { $credusage_names->{$_} } ($wanted_cred_usage, $cred_usage))
      );


}

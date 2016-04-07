#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;
use Test::More tests => 5;

BEGIN {
    use_ok('GSSAPI');
}

my $oidset;

my $status = GSSAPI::indicate_mechs( $oidset );

ok ( $status, q{ GSSAPI::indicate_mechs( $oidset ) } . $status );

SKIP: {
    unless ($status->major == GSS_S_COMPLETE  ) {
         skip( 'GSSAPI::indicate_mechs( $oidset ) failed ' . $status,  3 );
    }
    my $isin = 0;
    my @supported_mechs;

    my $status = $oidset->contains( gss_mech_krb5_old, $isin );
    ok ( $status, q{ $oidset->contains( gss_mech_krb5_old, $isin ) } . $status  );
    push @supported_mechs, 'KRB5 old Mechtype' if ( $status && $isin );

    $status = $oidset->contains( gss_mech_krb5, $isin );
    ok ( $status, q{ $oidset->contains( gss_mech_krb5, $isin )  } . $status );
    push @supported_mechs, 'Kerberos 5' if ( $status && $isin );

    $status = $oidset->contains( gss_mech_spnego, $isin );
    ok ( $status, q{ $oidset->contains( gss_mech_spnego, $isin ) } . $status );
    push @supported_mechs, 'SPNEGO' if ( $status && $isin );

    diag(  join ', ', @supported_mechs );
}
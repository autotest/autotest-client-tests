#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;

use GSSAPI qw(:all);
use Test::More tests => 1 + 3 * 11;


my $oidset = GSSAPI::OID::Set->new();
ok(ref $oidset eq 'GSSAPI::OID::Set', 'OID set created');

my %tobetested
    = (
       'gss_nt_user_name'         => gss_nt_user_name,
       'gss_nt_hostbased_service' => GSSAPI::OID::gss_nt_hostbased_service,
       'gss_mech_krb5_old'        => gss_mech_krb5_old,
       'gss_mech_krb5'            => gss_mech_krb5,
       'gss_mech_spnego'          => gss_mech_spnego,
       'gss_nt_exported_name'     => gss_nt_exported_name,
       'gss_nt_krb5_name'         => gss_nt_krb5_name,
       'gss_nt_krb5_principal'    => gss_nt_krb5_principal,
       'gss_mech_krb5_v2'         => gss_mech_krb5_v2,
       'gss_nt_machine_uid_name'  => gss_nt_machine_uid_name,
       'gss_nt_string_uid_name'   => gss_nt_string_uid_name,
      );

while ( my ($key,$value) = each %tobetested ) {
    check_oid( $oidset, $value ,$key);
}

#----------------------------------------------------
sub check_oid {
   my ($oidset, $oid, $text) = @_;
   my $isin = 0;

   my $status;

   # check if set does not contain oid
   $status = $oidset->contains( $oid , $isin );
   ok( ! $isin , "$text is not contained in OIDSET");

   # insert oid
   $status  = $oidset->insert( $oid );
   ok($status, "$text is inserted...  ");

   # check again if set does not contain oid
   $status = $oidset->contains( $oid , $isin );
   ok( $isin , "$text is contained in OIDSET");

}
#----------------------------------------------------
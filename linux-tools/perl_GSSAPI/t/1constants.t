#! /usr/bin/perl -w

use strict;

use ExtUtils::testlib;

use GSSAPI qw(:all);

my @constants_to_be_checked
    = qw( GSS_C_ACCEPT
          GSS_C_AF_APPLETALK
          GSS_C_AF_BSC
          GSS_C_AF_CCITT
          GSS_C_AF_CHAOS
          GSS_C_AF_DATAKIT
          GSS_C_AF_DECnet
          GSS_C_AF_DLI
          GSS_C_AF_DSS
          GSS_C_AF_ECMA
          GSS_C_AF_HYLINK
          GSS_C_AF_IMPLINK
          GSS_C_AF_INET
          GSS_C_AF_LAT
          GSS_C_AF_LOCAL
          GSS_C_AF_NBS
          GSS_C_AF_NS
          GSS_C_AF_NULLADDR
          GSS_C_AF_OSI
          GSS_C_AF_PUP
          GSS_C_AF_SNA
          GSS_C_AF_UNSPEC
          GSS_C_AF_X25
          GSS_C_ANON_FLAG
          GSS_C_BOTH
          GSS_C_CALLING_ERROR_MASK
          GSS_C_CALLING_ERROR_OFFSET
          GSS_C_CONF_FLAG
          GSS_C_DELEG_FLAG
          GSS_C_GSS_CODE
          GSS_C_INDEFINITE
          GSS_C_INITIATE
          GSS_C_INTEG_FLAG
          GSS_C_MECH_CODE
          GSS_C_MUTUAL_FLAG
          GSS_C_PROT_READY_FLAG
          GSS_C_QOP_DEFAULT
          GSS_C_REPLAY_FLAG
          GSS_C_ROUTINE_ERROR_MASK
          GSS_C_ROUTINE_ERROR_OFFSET
          GSS_C_SEQUENCE_FLAG
          GSS_C_SUPPLEMENTARY_MASK
          GSS_C_SUPPLEMENTARY_OFFSET
          GSS_C_TRANS_FLAG
          GSS_S_BAD_BINDINGS
          GSS_S_BAD_MECH
          GSS_S_BAD_NAME
          GSS_S_BAD_NAMETYPE
          GSS_S_BAD_QOP
          GSS_S_BAD_SIG
          GSS_S_BAD_STATUS
          GSS_S_CALL_BAD_STRUCTURE
          GSS_S_CALL_INACCESSIBLE_READ
          GSS_S_CALL_INACCESSIBLE_WRITE
          GSS_S_COMPLETE
          GSS_S_CONTEXT_EXPIRED
          GSS_S_CONTINUE_NEEDED
          GSS_S_CREDENTIALS_EXPIRED
          GSS_S_DEFECTIVE_CREDENTIAL
          GSS_S_DEFECTIVE_TOKEN
          GSS_S_DUPLICATE_ELEMENT
          GSS_S_DUPLICATE_TOKEN
          GSS_S_FAILURE
          GSS_S_GAP_TOKEN
          GSS_S_NAME_NOT_MN
          GSS_S_NO_CONTEXT
          GSS_S_NO_CRED
          GSS_S_OLD_TOKEN
          GSS_S_UNAUTHORIZED
          GSS_S_UNAVAILABLE
          GSS_S_UNSEQ_TOKEN
         );

use Test::More tests => 72;


do_constanttest( $_ ) foreach (@constants_to_be_checked);


SKIP: {
  if( GSSAPI::gssapi_implementation_is_heimdal() ) {
     skip('GSS_S_CRED_UNAVAIL not defined on Heimdal', 1);
  }
  do_constanttest( 'GSS_S_CRED_UNAVAIL' );
}


sub do_constanttest {
   my ( $constname ) = @_;
   my $constvalue;
   eval " \$constvalue = $constname";
   ok( ! $@,  "$constname" );
}
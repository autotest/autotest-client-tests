#!perl

use Test::More;

use Net::LDAP;
use Net::LDAP::Entry;
use Net::LDAP::Constant qw(LDAP_EXTENSION_CANCEL LDAP_CANCELED);
use Net::LDAP::Extension::Cancel;

BEGIN { require "t/common.pl" }


start_server()
? plan tests => 7
: plan skip_all => 'no server';


$ldap = client();
isa_ok($ldap, Net::LDAP, "client");

$rootdse = $ldap->root_dse;
isa_ok($rootdse, Net::LDAP::RootDSE, "root_dse");


SKIP: {
  skip("RootDSE does not offer cancel extension", 5)
    unless($rootdse->supported_extension(LDAP_EXTENSION_CANCEL)); 

  #$mesg = $ldap->start_tls;
  #ok(!$mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

  # cancel undef => should fail
  $cancel = $ldap->cancel(undef);
  ok($cancel->code, "cancel an undefined operation: " . $cancel->code . ": " . $cancel->error);

  # perform a search
  my $search = $ldap->search(
                       base     => $BASEDN,
                       filter   => '(objectclass=*)'
                     );

  # cancel the finished search => should fail
  $cancel = $ldap->cancel($search);
  ok($cancel->code, "cancel a finished operation: " . $cancel->code . ": " . $cancel->error);

  # switch to async mode
  $ldap->async(1);

  # perform a search (asynchronously)
  $search = $ldap->search(
                       base     => $BASEDN,
                       filter   => '(objectclass=*)',
                       callback => \&process_entry, # Call this sub for each entry
                     );

  # cancel the running search => should work [may fail, as it depends on the server's speed]
  $cancel = $ldap->cancel($search);
  ok(!$cancel->code, "cancel a running operation: " . $cancel->code . ": " . $cancel->error);
}


sub process_entry
{
  my $m = shift;
  my $e = shift;

  note($m->mesg_id.':'.$e->dn())  if ($ENV{TEST_VERBOSE} && ref($e));
}



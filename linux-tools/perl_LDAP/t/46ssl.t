#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server(version => 3, ssl => 1)
? plan tests => 15
: plan skip_all => 'no server';


SKIP: {
  skip('IO::Socket::SSL not installed', 15)
    unless (eval { require IO::Socket::SSL; } );

  $ldap = client();
  ok($ldap, "client");

  $mesg = $ldap->bind($MANAGERDN, password => $PASSWD, version => 3);

  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

  $mesg = $ldap->start_tls;
  ok(!$mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->start_tls;
  ok($mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
  ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

  compare_ldif("40",$mesg,$mesg->sorted);

  $ldap = client(ssl => 1);
  ok($ldap, "ssl client");

  $mesg = $ldap->start_tls;
  ok($mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
  ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

  compare_ldif("40",$mesg,$mesg->sorted);
}

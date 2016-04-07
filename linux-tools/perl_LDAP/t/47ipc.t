#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server(ipc => 1)
? plan tests => 18
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$mesg = $ldap->bind($MANAGERDN, password => $PASSWD);

ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

$mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

compare_ldif("40",$mesg,$mesg->sorted);

$ldap = client(ipc => 1);
ok($ldap, "ipc client");

$mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

compare_ldif("40",$mesg,$mesg->sorted);


SKIP: {
  skip('IO::Socket::SSL not installed')
    unless (eval { require IO::Socket::SSL; } );

  $mesg = $ldap->start_tls;
  ok(!$mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->start_tls;
  ok($mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
  ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

  compare_ldif("40",$mesg,$mesg->sorted);
}

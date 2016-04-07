#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server()
? plan tests => scalar(@URL) * 5 + 7
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

$mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

compare_ldif("40", $mesg, $mesg->sorted);

for my $url (@URL) {
  $ldap = client(url => $url);
  ok($ldap, "$url client");

  $mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');
  ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

  compare_ldif("40", $mesg, $mesg->sorted);
}


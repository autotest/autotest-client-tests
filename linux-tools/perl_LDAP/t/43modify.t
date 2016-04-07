#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server()
? plan tests => 7
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$mesg = $ldap->bind($MANAGERDN, password => $PASSWD);

ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

ok(ldif_populate($ldap, "data/42-in.ldif"), "data/42-in.ldif");

# load modify LDIF
ok(ldif_populate($ldap, "data/42-mod.ldif", 'modify'), "data/42-mod.ldif");

# now search the database

$mesg = $ldap->search(base => $BASEDN, filter => 'objectclass=*');

compare_ldif("42",$mesg,$mesg->sorted);


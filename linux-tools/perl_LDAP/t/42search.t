#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server()
? plan tests => 15
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$mesg = $ldap->bind($MANAGERDN, password => $PASSWD);

ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

ok(ldif_populate($ldap, "data/41-in.ldif"), "data/41-in.ldif");


# now search the database

# Exact searching
$mesg = $ldap->search(base => $BASEDN, filter => 'sn=jensen');
compare_ldif("41a",$mesg,$mesg->sorted);

# Or searching
$mesg = $ldap->search(base => $BASEDN, filter => '(|(objectclass=groupofnames)(sn=jones))');
compare_ldif("41b",$mesg,$mesg->sorted);

# And searching
$mesg = $ldap->search(base => $BASEDN, filter => '(&(objectclass=groupofnames)(cn=A*))');
compare_ldif("41c",$mesg,$mesg->sorted);

# Not searching
$mesg = $ldap->search(base => $BASEDN, filter => '(!(objectclass=person))');
compare_ldif("41d",$mesg,$mesg->sorted);


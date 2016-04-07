#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server(version => 3)
? plan tests => 4
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$schema = $ldap->schema;
ok($schema, "schema");

$ob = $schema->attribute('objectClass');
ok($ob, 'objectClass');

ok($ob->{syntax} eq '1.3.6.1.4.1.1466.115.121.1.38', 'syntax');

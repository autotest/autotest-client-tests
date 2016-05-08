#!perl

use Test::More;

BEGIN { require "t/common.pl" }


start_server(version => 3)
? plan tests => 4
: plan skip_all => 'no server';


$ldap = client();
ok($ldap, "client");

$dse = $ldap->root_dse;
ok($dse, "dse");

$dse->dump if $dse and $ENV{TEST_VERBOSE};

my @extn = $dse->get_value('supportedExtension');

ok($dse->supported_extension(@extn), 'supported_extension');

ok(!$dse->supported_extension('foobar'), 'extension foobar');



#!perl

use Test::More tests => 6;

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'LOGIN',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => 'none'
  },
);
ok($sasl, 'new');

is($sasl->mechanism, 'LOGIN', 'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost");

is($conn->mechanism, 'LOGIN', 'conn mechanism');

is($conn->client_start, '', 'client_start');

is($conn->client_step("username"), 'gbarr', 'client_step username');

is($conn->client_step("password"), 'fred', 'client_step password');

## XXX TODO check for success and extra steps

#!perl

use Test::More tests => 5;

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'EXTERNAL',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => 'none'
  },
);
ok($sasl, 'new');

is($sasl->mechanism, 'EXTERNAL', 'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost", "noplaintext");

is($conn->mechanism, 'EXTERNAL', 'conn mechanism');

is($conn->client_start, 'gbarr', 'client_start');

is($conn->client_step("xyz"),  undef, 'client_step');



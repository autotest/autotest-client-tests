#!perl

use Test::More tests => 5;

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'ANONYMOUS',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => 'none'
  },
);

ok($sasl, 'new');

is($sasl->mechanism, 'ANONYMOUS', 'mechanism is ANONYMOUS');

my $conn = $sasl->client_new("ldap","localhost");

is($conn->mechanism, 'ANONYMOUS', 'connection mechanism is ANONYMOUS');

my $initial = $conn->client_start;

ok($initial eq 'none', 	'client_start');

my $step = $conn->client_step("xyz");

is($step, 'none', 'client_step');


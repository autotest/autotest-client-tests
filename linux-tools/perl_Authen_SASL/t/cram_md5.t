#!perl

BEGIN {
  eval { require Digest::HMAC_MD5 }
}

use Test::More ($Digest::HMAC_MD5::VERSION ? (tests => 5) : (skip_all => 'Need Digest::HMAC_MD5'));

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'CRAM-MD5',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => 'none'
  },
);
ok($sasl, 'new');

is($sasl->mechanism, 'CRAM-MD5', 'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost", "noplaintext noanonymous");

is($conn->mechanism, 'CRAM-MD5', 'conn mechanism');


is($conn->client_start, '', 'client_start');

is($conn->client_step("xyz"), 'gbarr 36c931fe47f3fe9c7adbf810b3c7c4ad', 'client_step');



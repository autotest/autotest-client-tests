#!perl

use Test::More tests => 14;

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'PLAIN',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => 'none'
  },
);
ok($sasl, 'new');

is($sasl->mechanism, 'PLAIN', 'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost");

is($conn->mechanism, 'PLAIN', 'conn mechanism');
ok  $conn->need_step, "we need to *start* at the minimum";
ok !$conn->is_success, "no success yet";
ok !$conn->error, "and no error";

is($conn->client_start,  "none\0gbarr\0fred", 'client_start');
ok !$conn->need_step, "we're done, plain is kinda quick";
ok  $conn->is_success, "success!";
ok !$conn->error, "and no error";

is($conn->client_step("xyz"), undef, 'client_step');
ok !$conn->need_step, "we're done already";
ok  $conn->is_success, "sucess already";
ok !$conn->error, "and no error";



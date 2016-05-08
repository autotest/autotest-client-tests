#!perl

BEGIN {
  require Test::More;
  eval { require Digest::MD5 } or Test::More->import(skip_all => 'Need Digest::MD5');
  eval { require Digest::HMAC_MD5 } or Test::More->import(skip_all => 'Need Digest::HMAC_MD5');
}

use Test::More (tests => 27);

use Authen::SASL qw(Perl);

my $authname;

my $sasl = Authen::SASL->new(
  mechanism => 'DIGEST-MD5',
  callback => {
    user => 'gbarr',
    pass => 'fred',
    authname => sub { $authname },
  },
);
ok($sasl,'new');

is($sasl->mechanism, 'DIGEST-MD5', 'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost", "noplaintext noanonymous");

is($conn->mechanism, 'DIGEST-MD5', 'conn mechanism');

is($conn->client_start, '', 'client_start');
ok  $conn->need_step, "we need extra steps";
ok !$conn->is_success, "success will be later if we are good boys";
ok !$conn->error, "so far so good";

my $sparams = 'realm="elwood.innosoft.com",nonce="OA6MG9tEQGm2hh",qop="auth,auth-inf",algorithm=md5-sess,charset=utf-8';
# override for testing as by default it uses $$, time and rand
$Authen::SASL::Perl::DIGEST_MD5::CNONCE = "foobar";
$Authen::SASL::Perl::DIGEST_MD5::CNONCE = "foobar"; # avoid used only once warning
my $initial = $conn->client_step($sparams);
ok  $conn->need_step, "we need extra steps";
ok !$conn->is_success, "success will be later if we are good boys";
ok !$conn->error, "so far so good";

my @expect = qw(
  charset=utf-8
  cnonce="3858f62230ac3c915f300c664312c63f"
  digest-uri="ldap/localhost"
  nc=00000001
  nonce="OA6MG9tEQGm2hh"
  qop=auth
  realm="elwood.innosoft.com"
  response=9c81619e12f61fb2eed6bc8ed504ad28
  username="gbarr"
);

is(
  $initial,
  join(",", @expect),
  'client_step [1]'
);

my $response='rspauth=d1273170c120bae49cea49de9b4c5bdc';
$initial = $conn->client_step($response);
ok !$conn->need_step, "we're done";
ok $conn->is_success, "success !";
ok !$conn->error, "we did a good job";

is(
  $initial,
  '',
  'client_step [2]'
);

# .. .and now everything with an authname
is($conn->client_start, '', 'client_start');
ok  $conn->need_step, "we need extra steps";
ok !$conn->is_success, "success will be later if we are good boys";
ok !$conn->error, "so far so good";

$authname = 'meme';
$initial = $conn->client_step($sparams);
ok  $conn->need_step, "we need extra steps";
ok !$conn->is_success, "success will be later if we are good boys";
ok !$conn->error, "so far so good";

$expect[3] = 'nc=00000002';
$expect[7] = 'response=8d8afc5ff9cf3add40e50a5eaabb9aac';

is(
  $initial,
  join(",", 'authzid="meme"', @expect),
  'client_step + authname [1]'
);

$response='rspauth=dcb2b36dcd0750d3a7d0482fe1872769';
$initial = $conn->client_step($response);
ok !$conn->need_step, "we're done";
ok $conn->is_success, "success !";
ok !$conn->error, "we did a good job";

is(
  $initial,
  '',
  'client_step + authname [2]'
) or diag $conn->error;


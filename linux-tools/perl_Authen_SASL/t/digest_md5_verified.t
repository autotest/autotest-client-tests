#!perl

BEGIN {
  require Test::More;
  eval { require Digest::MD5 } or Test::More->import(skip_all => 'Need Digest::MD5');
  eval { require Digest::HMAC_MD5 } or Test::More->import(skip_all => 'Need Digest::HMAC_MD5');
}

use Test::More (tests => 8);

use Authen::SASL qw(Perl);

my $authname;

my $sasl = Authen::SASL->new(
  mechanism => 'DIGEST-MD5',
  callback => {
    user => 'fred',
    pass => 'gladys',
    authname => sub { $authname },
  },
);
ok($sasl,'new');

is($sasl->mechanism, 'DIGEST-MD5', 'sasl mechanism');

my $conn = $sasl->client_new("sieve","imap.spodhuis.org", "noplaintext noanonymous");

is($conn->mechanism, 'DIGEST-MD5', 'conn mechanism');

is($conn->client_start, '', 'client_start');

my $sparams = 'nonce="YPymzyi3YH8OILTBvSIuaul7RD3fIANDT2akHE6auBE=",realm="imap.spodhuis.org",qop="auth",maxbuf=4096,charset=utf-8,algorithm=md5-sess';
# override for testing as by default it uses $$, time and rand
$Authen::SASL::Perl::DIGEST_MD5::CNONCE = "foobar";
$Authen::SASL::Perl::DIGEST_MD5::CNONCE = "foobar"; # avoid used only once warning
my $initial = $conn->client_step($sparams);

ok(!$conn->code(), "SASL error: " . ($conn->code() ? $conn->error() : ''));

my @expect = qw(
  charset=utf-8
  cnonce="3858f62230ac3c915f300c664312c63f"
  digest-uri="sieve/imap.spodhuis.org"
  nc=00000001
  nonce="YPymzyi3YH8OILTBvSIuaul7RD3fIANDT2akHE6auBE="
  qop=auth
  realm="imap.spodhuis.org"
  response=3743421076899a855bafec1f7a9ed58a
  username="fred"
);

is(
  $initial,
  join(",", @expect),
  'client_step'
);

my $second = $conn->client_step('rspauth=4593215e1a0613328324b8325b975d96');

ok(!$conn->code(), "SASL error: " . ($conn->code() ? $conn->error() : ''));

is(
  $second,
  '',
  'client_step final verification'
);

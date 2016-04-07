#!perl

use Test::More tests => 7;

use Authen::SASL qw(Perl);

my $sasl = Authen::SASL->new(
  mechanism => 'PLAIN',
  callback => {
    user => 'gbarr',
    pass => \&cb_pass,
    authname => [ \&cb_authname, 1 ],
  },
);
ok($sasl, 'new');

is($sasl->mechanism,	'PLAIN',	'sasl mechanism');

my $conn = $sasl->client_new("ldap","localhost");

is($conn->mechanism,	'PLAIN',	'conn mechanism');

my $test = 4;

is($conn->client_start,	"none\0gbarr\0fred", "client_start");

is($conn->client_step("xyz"), undef, "client_step");

sub cb_pass {
  ok(1,'pass callback');
  'fred';
}

sub cb_authname {
  ok((@_ == 2 and $_[1] == 1), 'authname callback');
  'none';
}


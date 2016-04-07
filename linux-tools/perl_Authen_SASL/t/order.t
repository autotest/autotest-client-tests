#!perl

use Test::More tests => 75;

use Authen::SASL qw(Perl);

my %order = qw(
  ANONYMOUS	0
  LOGIN		1
  PLAIN		1
  CRAM-MD5	2
  EXTERNAL	2
  DIGEST-MD5	3
);
my $skip3 = !eval { require Digest::MD5 and $Digest::MD5::VERSION || $Digest::MD5::VERSION };

foreach my $level (reverse 0..3) {
  my @mech = grep { $order{$_} <= $level } keys %order;
  foreach my $n (1..@mech) {
    push @mech, shift @mech; # rotate
    my $mech = join(" ",@mech);
    print "# $level $mech\n";
    if ($level == 3 and $skip3) {
      SKIP: {
	skip "requires Digest::MD5", 5;
      }
      next;
    }
    my $sasl = Authen::SASL->new(
      mechanism => $mech,
      callback => {
	user => 'gbarr',
	pass => 'fred',
	authname => 'none'
      },
    );
    ok($sasl, "new");

    is($sasl->mechanism, $mech, "sasl mechanism");

    my $conn = $sasl->client_new("ldap","localhost");
    ok($conn, 'client_new');

    my $chosen = $conn->mechanism;
    ok($chosen, 'conn mechanism ' . ($chosen || '?'));

    is($order{$chosen}, $level, 'mechanism level');
  }
}

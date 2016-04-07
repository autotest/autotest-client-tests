#!perl

use Test::More;

use Net::LDAP qw(LDAP_UNAVAILABLE);

my $devnull = eval { require File::Spec; File::Spec->devnull } || "/dev/null";


(-e $devnull)
? plan tests => 5
: plan skip_all => 'no null device';


$::destroy = 0;
{
  my $ldap = Net::LDAP::Dummy->new("host", async => 1);
  $ldap->bind; # create an internal ref loop
  note(explain($ldap->inner))  if $ENV{TEST_VERBOSE};
}
ok($::destroy, '');

my $ref;
my $mesg;
$::destroy = 0;
{
  my $ldap = Net::LDAP::Dummy->new("host", async => 1);
  $mesg = $ldap->bind; # create an internal ref loop
  $ref = $ldap->inner->outer;
  is($ref == $ldap, '');
}
ok(!$::destroy, '');

$ref = undef;
ok($mesg->code == LDAP_UNAVAILABLE, '');

undef $mesg;
ok($::destroy, '');


package Net::LDAP::Dummy;

use IO::File;

BEGIN { @ISA = qw(Net::LDAP); }

sub connect_ldap {
  my $ldap = shift;
  $ldap->{net_ldap_socket} = IO::File->new("+> $devnull");
}

sub DESTROY {
  my $self = shift;
  $::destroy = 1 unless tied(%$self);
  $self->SUPER::DESTROY;
}

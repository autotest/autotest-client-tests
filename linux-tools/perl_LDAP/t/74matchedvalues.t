#!perl

use Test::More;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_CONTROL_MATCHEDVALUES);
use Net::LDAP::Control::MatchedValues;

BEGIN { require "t/common.pl" }


my @tests;

{ # parse DATA into a list (= tests) of hashes (= test parameters) of lists (= parameter values)
  local $/ = '';
  while(my $para = <DATA> ) {
    my @lines = split(/\n/, $para);
    my %params;
    chomp(@lines);
    @lines = grep(!/^\s*(?:#.*?)?$/, @lines);
    map { push(@{$params{$1}}, $2) if (/^(\w+):\s*(.*)$/) } @lines;
    push(@tests, \%params)  if (%params);
  }
}

start_server()
? plan tests => 4 + 3 * scalar(@tests)
: plan skip_all => 'no server';


$ldap = client();
isa_ok($ldap, Net::LDAP, "client");

$rootdse = $ldap->root_dse;
isa_ok($rootdse, Net::LDAP::RootDSE, "root_dse");


SKIP: {
  skip("RootDSE does not offer MatchedValues control", 2 + 3 * scalar(@tests))
    unless($rootdse->supported_control(LDAP_CONTROL_MATCHEDVALUES));

  #$mesg = $ldap->start_tls(%tlsargs);
  #ok(!$mesg->code, "start_tls yields: ". $m->error);

  $mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

  foreach my $test (@tests) {
    $control = Net::LDAP::Control::MatchedValues->new(matchedValues => $test->{match}->[0]);
    isa_ok($control, Net::LDAP::Control::MatchedValues, "control object");

    $mesg = $ldap->search(base => $test->{dn}->[0],
  		filter => $test->{filter} ? $test->{filter}->[0] : '(objectclass=*)',
  		scope => $test->{scope} ? $test->{scope}->[0] : 'sub',
  		attrs => $test->{attrs} || [ '*' ],
  		control => $control);
    ok(!$mesg->code, "search: " . $mesg->code . ": " . $mesg->error);

    my $success = 1;
    my $entry = $mesg->entry(0);
    foreach $attr (@{$test->{attrs}}) {
      my $vals = join(':', sort $entry->get_value($attr));
      my $expected = $test->{$attr} ? join(':', sort @{$test->{$attr}}) : '';

      $success = 0  if ($vals ne $expected);
    }
    ok($success, "values match expectations");
  }
}

__DATA__

## each section below represents one test; logic similar to , structure similar to LDIF
# each tests needs at least the elements
# - match:  the value of the MatchedValues control
# - dn:     the base-DN of the search
# - filter: the filter to use  (first element important only)

# one attribute, no wildcards
match: ((cn=Babs Jensen))
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (mail=bjensen@mailgw.umich.edu)
scope: base
attrs: cn
cn: Babs Jensen

# one attribute, wildcards
match: ((cn=Babs Jensen))
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (mail=bjensen@mailgw.umich.edu)
scope: base
attrs: cn
cn: Babs Jensen

# multiple attributes, wildcards
match: ((cn=* Jensen)(title=*Myth*))
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (mail=bjensen@mailgw.umich.edu)
scope: base
attrs: title
attrs: cn
title: Mythical Manager, Research Systems
cn: Barbara Jensen
cn: Babs Jensen

# one attribute, wildcards, no matching value
match: ((description=*LDAP*))
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (mail=bjensen@mailgw.umich.edu)
scope: base
attrs: description


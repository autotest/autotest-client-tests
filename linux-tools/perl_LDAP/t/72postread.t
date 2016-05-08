#!perl

use Test::More;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_CONTROL_POSTREAD);
use Net::LDAP::Control::PostRead;

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
? plan tests => 4 + 6 * scalar(@tests)
: plan skip_all => 'no server';


$ldap = client();
isa_ok($ldap, Net::LDAP, "client");

$rootdse = $ldap->root_dse;
isa_ok($rootdse, Net::LDAP::RootDSE, "root_dse");


SKIP: {
  skip("RootDSE does not offer PostRead control", 2 + 6 * scalar(@tests))
    unless($rootdse->supported_control(LDAP_CONTROL_POSTREAD));

  #$mesg = $ldap->start_tls(%tlsargs);
  #ok(!$mesg->code, "start_tls yields: ". $m->error);

  my $mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

  foreach my $test (@tests) {
    my $entry = Net::LDAP::Entry->new(@{$test->{dn}} ? $test->{dn}[0] : '');

    my $control = Net::LDAP::Control::PostRead->new(attrs => $test->{attrs});
    isa_ok($control, Net::LDAP::Control::PostRead, "control object");

    $entry->changetype('modify');
    foreach my $attr (@{$test->{attrs}}) {
      $entry->replace($attr => $test->{$attr} || []);
    }

    $mesg =  $entry->update($ldap, control => $control);
    ok(!$mesg->code, "modify: " . $mesg->code . ": " . $mesg->error);

    my ($previous) = $mesg->control( LDAP_CONTROL_POSTREAD );
    isa_ok($control, Net::LDAP::Control::PostRead, "response object");

    $entry = $previous->entry();
    isa_ok($entry, Net::LDAP::Entry, "entry object");

    my $postreadValue = join(':', map { sort $entry->get_value($_) } @{$test->{attrs}});

    $mesg = $ldap->search(base => @{$test->{dn}} ? $test->{dn}[0] : '',
                          filter => '(objectclass=*)',
                          scope => 'base',
                          attrs => $test->{attrs});
    ok(!$mesg->code, "search: ". $mesg->code . ": " . $mesg->error);

    $entry = $mesg->entry(0);
    my $origValue = join(':', map { sort $entry->get_value($_) } @{$test->{attrs}});
    is($postreadValue, $origValue, "value in PostRead control matches");
  }
}

__DATA__

## each section below represents one test; logic similar to , structure similar to LDIF
# each tests needs at least the elements
# - dn: the object to modify/perform the test on
# - attrs:  the attributes to change and use in PostRead control
# - $attr:  optional - the new values (if any) for the attribute $attr

# one attribute: replace a single value with another one
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
attrs: title
title: HyperMythical Manager, Research Systems

# one attribute: replace a single value attribute with multiple values
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
attrs: title
title: Uber-Mythical Manager, Research Systems
title: Cyber-Mythical Manager, Research Systems

# one attribute: delete all values
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
attrs: title

# multiple attribute: replace some values
dn: cn=All Staff,ou=Groups,o=University of Michigan,c=US
attrs: member
attrs: description
member: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
member: cn=Jane Doe, ou=Alumni Association, ou=People, o=University of Michigan, c=US
member: cn=John Doe, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
member: cn=Mark Elliot, ou=Alumni Association, ou=People, o=University of Michigan, c=US
member: cn=James A Jones 1, ou=Alumni Association, ou=People, o=University of Michigan, c=US
member: cn=Ursula Hampster, ou=Alumni Association, ou=People, o=University of Michigan, c=US
member: cn=Bjorn Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
description: Some of the sample data

# multiple attribute: delete one, update the other
dn: cn=All Staff,ou=Groups,o=University of Michigan,c=US
attrs: member
attrs: description
member: cn=Manager, o=University of Michigan, c=US


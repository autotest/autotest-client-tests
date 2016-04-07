#!perl

use Test::More;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_CONTROL_ASSERTION);
use Net::LDAP::Control::Assertion;

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
? plan tests => 4 + 2 * scalar(@tests)
: plan skip_all => 'no server';


$ldap = client();
isa_ok($ldap, Net::LDAP, "client");

$rootdse = $ldap->root_dse;
isa_ok($rootdse, Net::LDAP::RootDSE, "root_dse");


SKIP: {
  skip("RootDSE does not offer Assertion control", 2 + 2 * scalar(@tests))
    unless($rootdse->supported_control(LDAP_CONTROL_ASSERTION));

  #$mesg = $ldap->start_tls;
  #ok(!$mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");

  foreach my $test (@tests) {
    $control = Net::LDAP::Control::Assertion->new(assertion => $test->{assertion}->[0]);
    isa_ok($control, Net::LDAP::Control::Assertion, "control object");

    if ($test->{action}->[0] eq 'search') {
      $mesg = $ldap->search(base => $test->{dn}->[0],
		filter => $test->{filter} ? $test->{filter}->[0] : '(objectclass=*)',
		scope => $test->{scope} ? $test->{scope}->[0] : 'sub',
		control => $control);
      is($mesg->code, $test->{code}->[0] || 0,
		($test->{code}->[0] ? "search [expecting ".$test->{code}->[0]."]: " : "search: ") .
		$mesg->code . ": " . $mesg->error);
    }
    elsif ($test->{action}->[0] eq 'compare') {
      $mesg = $ldap->compare($test->{dn}->[0],
		attr => $test->{attr}->[0],
		value => $test->{value}->[0],
		control => $control);
      is($mesg->code, $test->{code}->[0] || 6,
		($test->{code}->[0] ? "compare [expecting ".$test->{code}->[0]."]: " : "search: ") .
		$mesg->code . ": " . $mesg->error);
    }
    elsif ($test->{action}->[0] eq 'modify') {
      $mesg = $ldap->modify($test->{dn}->[0],
		$test->{changetype}->[0] => {
			map { $_ => $test->{$_} } @{$test->{attrs}}
		},
		control => $control);
      is($mesg->code, $test->{code}->[0] || 0,
		($test->{code}->[0] ? "modify [expecting ".$test->{code}->[0]."]: " : "modify: ") .
		$mesg->code . ": " . $mesg->error);
    }
    elsif ($test->{action}->[0] eq 'moddn') {
      my %sup = $test->{newsuperior} ? ( newsuperior => $test->{newsuperior}->[0] ) : ();
      $mesg = $ldap->moddn($test->{dn}->[0],
		newrdn => $test->{newrdn}->[0],
		%sup,
		control => $control);
      is($mesg->code, $test->{code}->[0] || 0,
		($test->{code}->[0] ? "moddn [expecting ".$test->{code}->[0]."]: " : "moddn: ") .
		$mesg->code . ": " . $mesg->error);
    }
    elsif ($test->{action}->[0] eq 'delete') {
      $mesg = $ldap->delete($test->{dn}->[0],
		control => $control);
      is($mesg->code, $test->{code}->[0] || 0,
		($test->{code}->[0] ? "delete [expecting ".$test->{code}->[0]."]: " : "delete: ") .
		$mesg->code . ": " . $mesg->error);
    }
    else {
      ok(0, "illegal action");
      note("test: ", explain($test));
    }
  }
}

__DATA__

## each section below represents one test; logic similar to , structure similar to LDIF
# each tests needs at least the elements
# - assertion: the assertion filter to use
# - action:    the action on which the assertion is to be tested
# - dn:        (base-)DN to use in the operation
# - ...:       all other elements depend on the operation [see above]

# search (expect failing assertion)
action: search
dn: ou=People, o=University of Michigan, c=US
filter: (cn=Babs Jensen)
assertion: (title=Mythical Manager, Research Systems)
code: 122

# search
action: search
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (cn=Babs Jensen)
assertion: (title=Mythical Manager, Research Systems)

# modify
action: modify
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
assertion: (title=MegaMythical Manager, Research Systems)
changetype: replace
attrs: title
title: Uber-Mythical Manager, Research Systems
title: Hyper-Mythical Manager, Research Systems
code: 122

# modify
action: modify
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
assertion: (title=Mythical Manager, Research Systems)
changetype: replace
attrs: title
title: Uber-Mythical Manager, Research Systems
title: Hyper-Mythical Manager, Research Systems

# compare (expect failing assertion)
action: compare
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (cn=Babs Jensen)
assertion: (title=HyperMythical Manager, Research Systems)
attr: sn
value: Jensen
code: 122

# compare
action: compare
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
filter: (cn=Babs Jensen)
assertion: (title=Hyper-Mythical Manager, Research Systems)
attr: sn
value: Jensen

# moddn
action: moddn
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
newrdn: cn=Babs Jensen
assertion: (title=HyperMythical Manager, Research Systems)
code: 122

# moddn
action: moddn
dn: cn=Barbara Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
newrdn: cn=Babs Jensen
assertion: (title=Hyper-Mythical Manager, Research Systems)

# delete
action: delete
dn: cn=Babs Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
assertion: (title=HyperMythical Manager, Research Systems)
code: 122

# delete
action: delete
dn: cn=Babs Jensen, ou=Information Technology Division, ou=People, o=University of Michigan, c=US
assertion: (title=Hyper-Mythical Manager, Research Systems)


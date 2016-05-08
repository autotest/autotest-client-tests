#!perl
#
# The attribute given must have unique values over the entries
# returned from the search. This is because this test checks
# that the order of entries returned by 'attr' is the exact
# opposite of '-attr' this is not guaranteed if two entries have
# the same value for attr.

use Test::More;

BEGIN { require "t/common.pl" }

use Net::LDAP::LDIF;
use Net::LDAP::Control::Sort;
use Net::LDAP::Constant qw(
	LDAP_CONTROL_SORTREQUEST
	LDAP_CONTROL_SORTRESULT
	LDAP_SUCCESS
);


# @testcases is a list of ($order => $reversed) tuples
my @testcases = (
	[ 'cn:2.5.13.3' => '-cn:2.5.13.3' ] ,
	[ 'sn:2.5.13.3 uid:2.5.13.3' => '-sn:2.5.13.3 -uid:2.5.13.3' ]
);

start_server()
? plan tests => (4 + scalar(@testcases) * 9)
: plan skip_all => 'no server';


$ldap = client();
isa_ok($ldap, Net::LDAP, "client");

$rootdse = $ldap->root_dse;
isa_ok($rootdse, Net::LDAP::RootDSE, "root_dse");


SKIP: {
  skip("RootDSE does not offer sort control", 2 + scalar(@testcases) * 9)
    unless($rootdse->supported_control(LDAP_CONTROL_SORTREQUEST));

  #$mesg = $ldap->start_tls;
  #ok(!$mesg->code, "start_tls: " . $mesg->code . ": " . $mesg->error);

  $mesg = $ldap->bind($MANAGERDN, password => $PASSWD);
  ok(!$mesg->code, "bind: " . $mesg->code . ": " . $mesg->error);

  ok(ldif_populate($ldap, "data/40-in.ldif"), "data/40-in.ldif");
  
  foreach my $elem (@testcases) {
    my ($ordered,$reversed) = @{$elem};
    my @attrs = map { s/:.*$//; $_ } split(/\s+/, $ordered);
    my $sort = Net::LDAP::Control::Sort->new(order => $ordered);
    isa_ok($sort, Net::LDAP::Control::Sort, "sort control object");

    my $mesg = $ldap->search(
	      base	=> $BASEDN,
	      filter	=> '(objectclass=OpenLDAPperson)',
	      control	=> [ $sort ],
	    );
    is($mesg->code, LDAP_SUCCESS, "search: " . $mesg->code . ": " . $mesg->error);

    my ($resp) = $mesg->control( LDAP_CONTROL_SORTRESULT );
    ok($resp, 'LDAP_CONTROL_SORTRESULT response');

    ok($resp && $resp->result == LDAP_SUCCESS , 'LDAP_CONTROL_SORTRESULT success');

    if ($ENV{TEST_VERBOSE}) {
      my $rank = 0;
      foreach my $e ($mesg->entries) {
        note(++$rank, '. ', join(':', map { join(',',$e->get_value($_)) } @attrs));
      }
    }

    my $dn1 = join ";", map { $_->dn } $mesg->entries;

    $sort = Net::LDAP::Control::Sort->new(order => $reversed);
    isa_ok($sort, Net::LDAP::Control::Sort, "sort control object (reversed)");

    $mesg = $ldap->search(
	  base		=> $BASEDN,
	  filter	=> '(objectclass=OpenLDAPperson)',
	  control	=> [ $sort ],
	);
    is($mesg->code, LDAP_SUCCESS, 'search result');

    ($resp) = $mesg->control( LDAP_CONTROL_SORTRESULT );
    ok($resp, 'LDAP_CONTROL_SORTRESULT response');

    ok($resp && $resp->result == LDAP_SUCCESS , 'LDAP_CONTROL_SORTRESULT success');

    if ($ENV{TEST_VERBOSE}) {
      my $rank = 0;
      foreach my $e (reverse $mesg->entries) {
        note(++$rank,'. ',join(':', map { join(',',$e->get_value($_)) } @attrs));
      }
    }

    my $dn2 = join ";", map { $_->dn } reverse $mesg->entries;

    is($dn1, $dn2, 'sort order');
  }
}

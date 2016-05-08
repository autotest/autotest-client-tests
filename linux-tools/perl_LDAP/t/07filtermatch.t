#!perl

use Test::More;

use Net::LDAP::Entry;
use Net::LDAP::Filter;
use Net::LDAP::FilterMatch qw(Text::Soundex);

# Each line consists of an OPCODE-LIST and a DN,
# where
# - OPCODE-LIST is a comma spearated list of OPCODES,
#   each potentially prefixed with a TESTCASE prefix followed by :
#     OPCODE-LIST = OPCODE (, [ TESTCASE:] OPCODE )+
# - within the OPCODE-LIST each TESTCASE prefix needs to be unique
# - no TESTCASE prefix means: default result
# - OPCODES are
#     yes   $filter->match() returns true
#     no    $filter->match() returns false
#     fail  $filter->match() returns undef

# To keep the order of tests, @tests is an array of ($filterstring => @ops) tuples
my @tests = map { /^([\w:,]+)\s+(\(.*\))/ &&  { $2 => [ split(/,/, $1) ] } }
                grep(/^[\w:,]+\s+\(.*\)/, <DATA>);

# The elements of the @testcases array are the TESTCASE prefixes described above
my @testcases = qw/raw schema/;


# calculate number of tests:
plan tests => 3 +			# general preparation
              scalar(@tests) *		# @tests is a list of ($filter => \@ops) pairs
              ( 1 +			# one Net::LDAP::Filter test per ...
                scalar(@testcases));    # ... every test case


my $entry = Net::LDAP::Entry->new(
	'cn=John Doe, ou=Information Technology Division, ou=People, o=University of Michigan, c=US',
	objectClass => [ 'OpenLDAPperson' ],
	cn => [ 'John Doe', 'Jonathon Doe' ],
	uid => [ 'john' ],
	sn => [ 'Doe' ],
	givenName => [ qw/John Jonathon/ ],
	mailPreferenceOption => 2,
	# uidnumber is not a legal attribute of OpenLDAPperson:
	# does not matter here, but will not load into an LDAP server
	uidNumber => 1012,
	o => 'University of Michigan',
	postalAddress => [ 'ITD $ 535 W. William $ Ann Arbor, MI 48109' ],
	seeAlso => [ 'cn=All Staff, ou=Groups, o=University of Michigan, c=US' ],
	homePostalAddress => [ '912 East Bllvd $ Ann Arbor, MI 48104' ],
	title => [ 'System Administrator, Information Technology Division' ],
	description => [ 'overworked!' ],
	mail => [ 'johnd@mailgw.umich.edu' ],
	homePhone => [ '+1 313 555 3774' ],
	pager => [ '+1 313 555 6573' ],
	facsimileTelephoneNumber => [ '+1 313 555 4544' ],
	telephoneNumber => [ '+1 313 555 9394' ],
	createTimestamp => '20090209123456Z',
	creatorsName => 'cn=James A Jones 2, ou=Information Technology Division, ou=People, o=University of Michigan, c=US',
	modifyTimestamp => '20121102212634Z',
	modifiersName => 'cn=John Doe, ou=Information Technology Division, ou=People, o=University of Michigan, c=US');
isa_ok($entry, Net::LDAP::Entry, 'entry object created');

my $schema = Net::LDAP::Schema->new();
isa_ok($schema, Net::LDAP::Schema, 'schema object created');

ok($schema->parse('data/schema.in'), "schema loaded: ".($schema->error ? $schema->error : ''));

note('Schema: ', explain($schema))  if ($ENV{TEST_VERBOSE});


foreach my $elem (@tests) {
  my ($filterstring, $ops) = %{$elem};
  my $filter = Net::LDAP::Filter->new($filterstring);
  isa_ok($filter, Net::LDAP::Filter, 'filter object created');

  #note("$filterstring => ", explain($filter));

  SKIP: {
    eval { require Text::Soundex };
    skip("Text::Soundex not installed", scalar(@testcases))  if ($@);

    for my $case (@testcases) {
      my ($op) = grep(/^$case:/, @{$ops});

      ($op) = grep(/^[^:]+$/, @{$ops})  if (!$op);
      $op =~ s/^$case://;

      my $match = $filter->match($entry, $case eq 'schema' ? $schema : undef);
      foreach ($op) {
        /fail/      &&  ok(!defined($match), "$filterstring should cause failure in $case mode");
        /yes/       &&  ok($match, "$filterstring should match in $case mode");
        /(todo|no)/ &&  ok(!$match, "$filterstring should not match in $case mode");
      }
    }
  }
}


__DATA__

## "basic" match
# caseIgnoreIA5Match
yes		(mail=johnd@mailgw.umich.edu)
# caseIgnoreListMatch
yes		(postaladdress=ITD $ 535 W. William $ Ann Arbor, MI 48109)
# caseIgnoreMatch
no		(cn=Babs Jensen)
yes		(!(cn=Tim Howes))
yes		(cn=John Doe)
# distinguishedNameMatch
yes,raw:no	(seeAlso=cn=All Staff, OU=Groups, o=University of Michigan,c=US)
# facsimileNumberMatch
#yes		(facsimiletelephoneNumber=+1 313 555 4544)
# generalizedTimeMatch
yes		(createTimestamp>=19970101120000Z)
yes		(createTimestamp<=25250101000000Z)
# integerMatch
yes		(uidNumber=1012)
no		(uidNumber=1011)
# integerMatch not listed in attributeType => fail with schema
fail,raw:yes	(mailPreferenceOption=2)
# objectIdentifierMatch
no		(objectclass=top)
yes		(objectclass=OpenLDAPPerson)
# telephoneNumberMatch
yes		(telephoneNumber=+1 313 555 9394)
yes,raw:no	(homephone=+13135553774)
yes,raw:no	(homephone=001313 5553774)
# generalizedTimeOrderingMatch
yes		(createTimestamp>=19970101120000Z)
yes		(createTimestamp<=25250101000000Z)
# integerOrderingMatch
yes		(uidNumber>=1000)
yes		(uidNumber<=2000)
# integerOrderingMatch not listed in attributeType => fail with schema
fail,raw:yes	(mailpreferenceOption>=2)
# caseIgnoreIA5SubstringsMatch
yes		(mail=johnd@*)
yes		(mail=johnd*@*umich.edu)
# caseIgnoreListSubstringsMatch
yes		(postaladdress=ITD $ * William $ Ann Arbor, MI 48109)
# caseIgnoreSubstringsMatch
yes		(cn=j*)
no		(cn=*a)
yes		(cn=*a*)
yes		(o=univ*of*mich*)
# facsimileNumberSubstringsMatch
#yes		(facsimiletelephoneNumber=*1 313 555 4544)
#yes		(facsimiletelephoneNumber=+1*555*)
# telephoneNumberSubstringsMatch
yes		(telephoneNumber=+1*313 555 9394)
yes		(telephoneNumber=+1*313*)
yes,raw:no	(homephone=+131355*)
yes,raw:no	(homephone=0013*774)

## presence match
yes		(cn=*)

## approx match
yes		(cn~=Jonathon Doe)
yes		(cn~=jonathon doe)
yes		(cn~=jonathan doe)
yes		(cn~=jonothan doe)
yes		(cn~=jonathan do)
yes		(cn~=john doe)
yes		(cn~=jon doe)
yes		(cn~=jomatan doe)
yes		(cn~=jonatan oe)
yes		(cn~=jon dee)

## extensible match
yes		(cn:dn:=John Doe)
yes		(:dn:caseIgnoreMatch:=People)
yes		(mailPreferenceOption:integerBitAndMatch:=2)
yes,raw:no	(mailPreferenceOption:integerBitOrMatch:=3)
yes		(!(mailPreferenceOption:integerBitAndMatch:=1))
yes	 	(!(mailPreferenceOption:integerBitAndMatch:=3))
yes,raw:fail	(:caseignoreMatch:=University of michigan)

# EOF

#!perl -w

use Test::More tests => 14;
use Net::LDAP::Schema;

my $schema = Net::LDAP::Schema->new( "data/schema.in" ) or die "Cannot open schema";
isa_ok($schema, Net::LDAP::Schema, 'load schema file');

my @atts = $schema->all_attributes();
is(@atts, 265, 'number of attribute types in schema');
print "The schema contains ", scalar @atts, " attributes\n";

my @ocs = $schema->all_objectclasses();
is(@ocs, 66, 'number of object classes in schema');
print "The schema contains ", scalar @ocs, " object classes\n";

my @mrs = $schema->all_matchingrules();
is(@mrs, 40, 'number of matching rules in schema');
print "The schema contains ", scalar @mrs, " matching rules\n";

my @mrus = $schema->all_matchingruleuses();
is(@mrus, 34, 'number of matching rule uses in schema');
print "The schema contains ", scalar @mrus, " matching rule uses\n";

my @stxs = $schema->all_syntaxes();
is(@stxs, 32, 'number of LDAP syntaxes in schema');
print "The schema contains ", scalar @stxs, " LDAP syntaxes\n";

%namechildren = map { $_->{name} => 1 }
                    grep { grep(/^name$/i, @{$_->{sup}}) }
                         $schema->all_attributes();
is(scalar(keys(%namechildren)), 13, "attributes derived from 'name'");

@atts = $schema->must( "person" );
is(join(' ', sort map { lc $_->{name} } @atts),
   join(' ', sort map lc, qw(cn sn objectClass)), 'mandatory attributes');
print "The 'person' OC must have these attributes [",
		join(',', map $_->{name}, @atts),
		"]\n";

@atts = $schema->may( "mhsOrganizationalUser" );
ok(!@atts, 'optional attributes');
print "The 'mhsOrganizationalUser' OC may have these attributes [",
		join(',', map $_->{name}, @atts),
		"]\n";

@super = $schema->superclass('OpenLDAPperson');
is(join(' ', sort map lc, @super),
   join(' ', sort map lc, qw(pilotPerson inetOrgPerson)), 'superclass');

$mru = $schema->matchingruleuse('generalizedtimematch');
is(join(' ', sort map lc, @{$mru->{applies}}),
   join(' ', sort map lc, qw(createTimestamp modifyTimestamp)), 'attribute types a matching rule applies to');
   
@binarysyntaxes = map { $_->{name} } grep { $_->{'x-binary-transfer-required'} } $schema->all_syntaxes();
is(scalar(@binarysyntaxes), 5, "number of syntaxes that need ';binary' appended to the attribute type");

ok(! defined($schema->attribute('distinguishedName')->{max_length}), 'infinite length attribute type');

is($schema->attribute('userPassword')->{max_length}, 128, 'attribute type max. length');

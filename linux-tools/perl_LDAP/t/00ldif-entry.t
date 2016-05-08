#!perl

BEGIN {
  require "t/common.pl";
}

use Test::More tests => 16;
use File::Compare qw(compare_text);

use Net::LDAP::LDIF;

my $infile   = "data/00-in.ldif";
my $outfile1 = "$TEMPDIR/00-out1.ldif";
my $outfile2 = "$TEMPDIR/00-out2.ldif";
my $cmpfile1 = "data/00-cmp.ldif";
my $cmpfile2 = $infile;

my $ldif = Net::LDAP::LDIF->new($infile,"r");

my $entry0_ldif = <<'LDIF';
dn: o=University of Michigan, c=US
objectclass: top
objectclass: organization
objectclass: domainRelatedObject
objectclass: quipuObject
objectclass: quipuNonLeafObject
l: Ann Arbor, Michigan
st: Michigan
streetaddress: 535 West William St.
o: University of Michigan
o: UMICH
o: UM
o: U-M
o: U of M
description: The University of Michigan at Ann Arbor
postaladdress: University of Michigan $ 535 W. William St. $ Ann Arbor, MI 481
 09 $ USpostalcode: 48109
telephonenumber: +1 313 764-1817
lastmodifiedtime: 930106182800Z
lastmodifiedby: cn=manager, o=university of michigan, c=US
associateddomain: umich.edu
LDIF

my $e = $ldif->read_entry;
my @lines = $ldif->current_lines;
is(join("",@lines),$entry0_ldif,"ldif lines");

my @entry = ($e, $ldif->read);

ok($ldif->version == 1, "version == 1");

Net::LDAP::LDIF->new($outfile1,"w")->write(@entry);
Net::LDAP::LDIF->new($outfile2,"w", version => 1)->write(@entry);

ok(!compare_text($cmpfile1,$outfile1), $cmpfile1);

ok(!compare_text($cmpfile2,$outfile2), $cmpfile2);


is($e->ldif, "\n$entry0_ldif", "ldif method");


is($e->ldif(change => 1), <<'LDIF', "ldif method");

dn: o=University of Michigan, c=US
changetype: add
objectclass: top
objectclass: organization
objectclass: domainRelatedObject
objectclass: quipuObject
objectclass: quipuNonLeafObject
l: Ann Arbor, Michigan
st: Michigan
streetaddress: 535 West William St.
o: University of Michigan
o: UMICH
o: UM
o: U-M
o: U of M
description: The University of Michigan at Ann Arbor
postaladdress: University of Michigan $ 535 W. William St. $ Ann Arbor, MI 481
 09 $ USpostalcode: 48109
telephonenumber: +1 313 764-1817
lastmodifiedtime: 930106182800Z
lastmodifiedby: cn=manager, o=university of michigan, c=US
associateddomain: umich.edu
LDIF


$e->changetype('modify');
$e->delete('objectclass');
$e->delete('o',['UM']);
$e->add('counting',[qw(one two three)]);
$e->add('first',[qw(1 2 3)], 'second',[qw(a b c)]);
$e->replace('telephonenumber' => ['911']);

is($e->ldif, <<'LDIF',"changes ldif");

dn: o=University of Michigan, c=US
changetype: modify
delete: objectclass
-
delete: o
o: UM
-
add: counting
counting: one
counting: two
counting: three
-
add: first
first: 1
first: 2
first: 3
-
add: second
second: a
second: b
second: c
-
replace: telephonenumber
telephonenumber: 911
LDIF

is($e->ldif(change => 0), <<'LDIF',"changes ldif");

dn: o=University of Michigan, c=US
l: Ann Arbor, Michigan
st: Michigan
streetaddress: 535 West William St.
o: University of Michigan
o: UMICH
o: U-M
o: U of M
description: The University of Michigan at Ann Arbor
postaladdress: University of Michigan $ 535 W. William St. $ Ann Arbor, MI 481
 09 $ USpostalcode: 48109
telephonenumber: 911
lastmodifiedtime: 930106182800Z
lastmodifiedby: cn=manager, o=university of michigan, c=US
associateddomain: umich.edu
counting: one
counting: two
counting: three
first: 1
first: 2
first: 3
second: a
second: b
second: c
LDIF

$outfile = "$TEMPDIR/00-out3.ldif";
$cmpfile = "data/00-cmp2.ldif";

$ldif = Net::LDAP::LDIF->new($outfile,"w");
$ldif->write($e);
$ldif->write_cmd($e);
$ldif->done;
ok(!compare_text($cmpfile,$outfile), $cmpfile);

$e->add('name' => 'Graham Barr');
$e->add('name;en-us' => 'Bob');

is(join(":",sort $e->attributes),
   "associateddomain:counting:description:first:l:lastmodifiedby:lastmodifiedtime:name:name;en-us:o:postaladdress:second:st:streetaddress:telephonenumber",
   'attributes');

is(join(":",sort $e->attributes(nooptions => 1)),
   "associateddomain:counting:description:first:l:lastmodifiedby:lastmodifiedtime:name:o:postaladdress:second:st:streetaddress:telephonenumber",
   "attributes - nooptions");

$r = $e->get_value('name', asref => 1);
ok(($r and @$r == 1 and $r->[0] eq 'Graham Barr'), "name eq Graham Barr");

$r = $e->get_value('name;en-us', asref => 1);
ok(($r and @$r == 1 and $r->[0] eq 'Bob'), "name;en-us eq Bob");

$r = $e->get_value('name', alloptions => 1, asref => 1);
ok(($r and  join("*", sort keys %$r) eq "*;en-us"), "name keys");

ok(($r and $r->{''} and @{$r->{''}} == 1 and $r->{''}[0] eq 'Graham Barr'), "name alloptions");

ok(($r and $r->{';en-us'} and @{$r->{';en-us'}} == 1 and $r->{';en-us'}[0] eq 'Bob'), "name alloptions Bob");


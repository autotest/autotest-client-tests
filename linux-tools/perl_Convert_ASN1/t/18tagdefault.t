#!/usr/local/bin/perl

#
# Test that default EXPLICIT tagging works.
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..25\n";

btest 1, $asn = Convert::ASN1->new(encoding=>'DER',
                                   tagdefault=>'EXPLICIT') or warn $asn->error;

# Tests from X.690-0207, section 8.14.3
my $value = "Jones";
btest 2, $asn->prepare(q(
     Type1 ::= VisibleString
     Type2 ::= [APPLICATION 3] IMPLICIT Type1
     Type3 ::= [2] Type2
     Type4 ::= [APPLICATION 7] IMPLICIT Type3
     Type5 ::= [2] IMPLICIT Type2
)) or warn $asn->error;

# Type 1
btest 3, $type1 = $asn->find('Type1');
$result = pack("H*", "1A054A6F6E6573");
stest 4, $result, $type1->encode($value) or warn $asn->error;
btest 5, $ret = $type1->decode($result) or warn $asn->error;
stest 6, $value, $ret;

# Type 2
btest 7, $type2 = $asn->find('Type2');
$result = pack("H*", "43054A6F6E6573");
stest 8, $result, $type2->encode($value) or warn $asn->error;
btest 9, $ret = $type2->decode($result) or warn $asn->error;
stest 10, $value, $ret;

# Type 3
btest 11, $type3 = $asn->find('Type3');
$result = pack("H*", "A20743054A6F6E6573");
stest 12, $result, $type3->encode($value) or warn $asn->error;
btest 13, $ret = $type3->decode($result) or warn $asn->error;
stest 14, $value, $ret;

# Type 4
btest 15, $type4 = $asn->find('Type4');
$result = pack("H*", "670743054A6F6E6573");
stest 16, $result, $type4->encode($value) or warn $asn->error;
btest 17, $ret = $type4->decode($result) or warn $asn->error;
stest 18, $value, $ret;

# Type 5
btest 19, $type5 = $asn->find('Type5');
$result = pack("H*", "82054A6F6E6573");
stest 20, $result, $type5->encode($value) or warn $asn->error;
btest 21, $ret = $type5->decode($result) or warn $asn->error;
stest 22, $value, $ret;

# Test EXPLICIT tagging a nested SEQUENCE.
btest 23, $asn->prepare(q(
         X  ::= [APPLICATION 10] Y
         Y  ::= SEQUENCE {
                v [1] INTEGER,
                b [4] Z
         }
         Z ::= SEQUENCE {
             n [7] INTEGER,
             e [8] SEQUENCE OF INTEGER
         }
)) or warn $asn->error;
btest 24, $X = $asn->find('X');
$value = { v => 5,b => { n => 117, e=>[18,17,16,23] }};
$result = pack("H*", "6a20301ea103020105a4173015a703020175a80e300c020112020111020110020117");
stest 25, $result, $X->encode($value) or warn $asn->error;

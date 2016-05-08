#!/usr/local/bin/perl

#
# Test the use of sequences
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..27\n";


# Encode a "version 1" message
btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  SET {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    str [3] STRING,
    ...
  }
)) or warn $asn->error;

btest 3, $pdu = $asn->encode(integer => 1, bool => 0, str => "A string") or warn $asn->error;
btest 4, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 5, 1, $ret->{integer};
ntest 6, 0, $ret->{bool};
stest 7, "A string", $ret->{str};

# Decode a "version 1" message with a "version 2" decoder
btest 8, $asn->prepare(q(
  SET {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    str [3] STRING,
    ...,
    integer2 [4] INTEGER
  }
)) or warn $asn->error;
btest 9, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 10, 1, $ret->{integer};
ntest 11, 0, $ret->{bool};
stest 12, "A string", $ret->{str};
btest 13, !defined($ret->{integer2});


# Encode a "version 2" message
btest 14, $pdu = $asn->encode(integer => 1, bool => 0, str => "A string", integer2 => 2) or warn $asn->error;
btest 15, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 16, 1, $ret->{integer};
ntest 17, 0, $ret->{bool};
stest 18, "A string", $ret->{str};
ntest 19, 2, $ret->{integer2};


# Decode a "version 2" message with a "version 1" decoder
btest 20, $asn->prepare(q(
  SET {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    str [3] STRING,
    ...
  }
)) or warn $asn->error;
btest 21, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 22, 1, $ret->{integer};
ntest 23, 0, $ret->{bool};
stest 24, "A string", $ret->{str};
btest 25, !defined($ret->{integer2});


# OPTIONAL-ity check: integer2 is NOT optional during encode.
btest 26, $asn->prepare(q(
  SET {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    str [3] STRING,
    ...,
    integer2 [4] INTEGER
  }
)) or warn $asn->error;
btest 27, !defined( $asn->encode(integer => 1, bool => 0, str => "A string") );

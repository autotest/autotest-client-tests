#!/usr/local/bin/perl

#
# Test the use of sequences
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..19\n";


# Encode a "version 1" message
btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  CHOICE {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    ...
  }
)) or warn $asn->error;

btest 3, $pdu = $asn->encode(integer => 1) or warn $asn->error;
btest 4, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 5, 1, $ret->{integer};
btest 6, !defined($ret->{bool});
btest 7, !defined($ret->{str});

# Decode a "version 1" message with a "version 2" decoder
btest 8, $asn->prepare(q(
  CHOICE {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    ...,
    str [3] STRING
  }
)) or warn $asn->error;
btest 9, $ret = $asn->decode($pdu) or warn $asn->error;
ntest 10, 1, $ret->{integer};
btest 11, !defined($ret->{bool});
btest 12, !defined($ret->{str});


# Encode a "version 2" message
btest 13, $pdu = $asn->encode(str => "A string") or warn $asn->error;
btest 14, $ret = $asn->decode($pdu) or warn $asn->error;
btest 15, !defined($ret->{int});
btest 16, !defined($ret->{bool});
stest 17, "A string", $ret->{str};


# Decode a "version 2" message with a "version 1" decoder
btest 18, $asn->prepare(q(
  CHOICE {
    integer [1] INTEGER,
    bool [2] BOOLEAN,
    ...
  }
)) or warn $asn->error;
btest 19, !defined($ret = $asn->decode($pdu));

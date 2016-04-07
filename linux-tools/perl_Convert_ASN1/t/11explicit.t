#!/usr/local/bin/perl

BEGIN { require 't/funcs.pl' }

use Convert::ASN1;

print "1..4\n";

my $asn;

btest 1, $asn = Convert::ASN1->new or warn $asn->error;
btest 2, $asn->prepare(q(
  Message ::=  CHOICE
  {
    a A,
    b B
  }

  A ::= [2] EXPLICIT INTEGER
  B ::= [3] EXPLICIT INTEGER

 )) || die $asn->error;

my $mm = $asn->find("Message") || die $asn->error;

my $buffer = pack("H*","a203020105");

my $input = { a => 5 };

my $result = $mm->encode($input) || die $mm->error;
stest 3, $buffer, $result;
rtest 4, $input, $mm->decode($buffer);

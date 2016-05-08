#!/usr/bin/perl

# This is a regression test for this bug:
#
# https://rt.cpan.org/Ticket/Display.html?id=76696
#
# <<<
# Specifying ->keep_blanks(0) has no effect on parse_balanced_chunk anymore.
# The script below used to pass with XML::LibXML 1.69, but is broken since
# 1.70 and also with the newest 1.96.
# >>>
#
# Thanks to SREZIC for the report, the test and a patch.

use strict;
use warnings;

use Test::More tests => 1;

use XML::LibXML;

my $xml = <<'EOF';
<bla> <foo/> </bla>
EOF

my $p = XML::LibXML->new;
$p->keep_blanks(0);

# TEST
is (
    scalar( $p->parse_balanced_chunk($xml)->serialize() ),
    "<bla><foo/></bla>\n",
    'keep_blanks(0) removes the blanks after a roundtrip.',
);

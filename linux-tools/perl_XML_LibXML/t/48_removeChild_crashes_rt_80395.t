#!/usr/bin/perl

# See:
#
# https://rt.cpan.org/Public/Bug/Display.html?id=80395

use strict;
use warnings;

use Test::More tests => 1;

use XML::LibXML;

my $xml = <<EOF;
<!DOCTYPE bug [
<!ENTITY myent "xyz">
]>
<bug>
  <elem>&myent;</elem>
</bug>
EOF

my $dom = XML::LibXML->load_xml (string => $xml,
                                 expand_entities => 0);
my $root = $dom->documentElement;

my @nodes = $root->childNodes;
foreach my $node (@nodes) {
    next if $node->nodeType != XML_ELEMENT_NODE;
    next if $node->nodeName ne 'elem';

    $root->removeChild ($node);
}

# TEST
ok(1, "Code did not crash.");

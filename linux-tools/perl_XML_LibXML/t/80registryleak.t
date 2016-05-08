
use strict;
use warnings;

use Test::More tests => 2;
use XML::LibXML;

my $p = XML::LibXML->new();
# TEST
ok($p, 'Parser was initialized.');

my $xml = <<EOX;
<?xml version="1.0"?>
<root><child/></root>
EOX

{
my $doc = $p->parse_string($xml);
my $root = $doc->documentElement;
my $child = $root->firstChild;
}

# TEST
is (scalar(XML::LibXML::_leaked_nodes()), 0, '0 leaked nodes');

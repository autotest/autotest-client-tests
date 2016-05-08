# Test file created outside of h2xs framework.
# Run this like so: `perl 44extent.t'
#   pajas@ufal.mff.cuni.cz     2009/09/24 13:18:43

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More;

use XML::LibXML;

use IO::Handle;

STDOUT->autoflush(1);
STDERR->autoflush(1);

if (XML::LibXML::LIBXML_VERSION() < 20627)
{
    plan skip_all => "skipping for libxml2 < 2.6.27";
}
else
{
    plan tests => 7;
}

my $parser = XML::LibXML->new({
  expand_entities => 1,
  ext_ent_handler => \&handler,
});

sub handler {
  return join(",",@_);
}

my $xml = <<'EOF';
<?xml version="1.0"?>
<!DOCTYPE foo [
<!ENTITY a PUBLIC "//foo/bar/b" "file:/dev/null">
<!ENTITY b SYSTEM "file:///dev/null">
]>
<root>
  <a>&a;</a>
  <b>&b;</b>
</root>
EOF
my $xml_out = $xml;
$xml_out =~ s{&a;}{file:/dev/null,//foo/bar/b};
$xml_out =~ s{&b;}{file:///dev/null,};

my $doc = $parser->parse_string($xml);

# TEST
is( $doc->toString(), $xml_out, ' TODO : Add test name' );

my $xml_out2 = $xml; $xml_out2 =~ s{&[ab];}{<!-- -->}g;

$parser->set_option( ext_ent_handler => sub { return '<!-- -->' } );
$doc = $parser->parse_string($xml);
# TEST
is( $doc->toString(), $xml_out2, ' TODO : Add test name' );

$parser->set_option( ext_ent_handler=>sub{ '' } );
$parser->set_options({
  expand_entities => 0,
  recover => 2,
});
$doc = $parser->parse_string($xml);
# TEST
is( $doc->toString(), $xml, ' TODO : Add test name' );

# TEST:$el=2;
foreach my $el ($doc->findnodes('/root/*')) {
  # TEST*$el
  ok ($el->hasChildNodes, ' TODO : Add test name');
  # TEST*$el
  ok ($el->firstChild->nodeType == XML_ENTITY_REF_NODE, ' TODO : Add test name');
}


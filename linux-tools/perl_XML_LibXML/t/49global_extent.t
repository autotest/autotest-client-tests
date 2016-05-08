use strict;
use warnings;

use Test::More;
use XML::LibXML;

if (XML::LibXML::LIBXML_VERSION() < 20627) {
    plan skip_all => "skipping for libxml2 < 2.6.27";
}
else
{
    plan tests => 1;
}

sub handler {
  return "ENTITY:" . join(",",@_);
}

# global entity loader
XML::LibXML::externalEntityLoader(\&handler);

my $parser = XML::LibXML->new({
  expand_entities => 1,
});

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
$xml_out =~ s{&a;}{ENTITY:file:/dev/null,//foo/bar/b};
$xml_out =~ s{&b;}{ENTITY:file:///dev/null,};

my $doc = $parser->parse_string($xml);

# TEST
is( $doc->toString(), $xml_out );

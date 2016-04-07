
use strict;
use warnings;

use Test::More tests => 1;

use XML::LibXML;

# XML::LibXML->load_catalog( "example/catalog.xml" );

# the following document should not be able to get parsed
# if the catalog is not available

my $doc = XML::LibXML->new( catalog => "example/catalog.xml" )->parse_string(<<EOF);
<!DOCTYPE article
  PUBLIC "-//Perl//XML LibXML V4.1.2//EN"
  "http://axkit.org/xml-libxml/test.dtd">
<article>
<pubData>Something here</pubData>
<pubArticleID>12345</pubArticleID>
<pubDate>2001-04-01</pubDate>
<pubName>XML.com</pubName>
<section>Foo</section>
<lead>Here's some leading text</lead>
<rest>And here is the rest...</rest>
</article>
EOF

# TEST
ok($doc, 'Doc was parsed with catalog');

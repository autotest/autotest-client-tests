
use strict;
use warnings;

use Test::More tests => 2;

use XML::LibXML;

my $doc = XML::LibXML->createDocument;

my $t1 = $doc->createTextNode( "foo" );
my $t2 = $doc->createTextNode( "bar" );

$t1->addChild( $t2 );

eval {
    my $v = $t2->nodeValue;
};
# TEST
ok($@, 'An exception was thrown');

# TEST
ok(1, 'End');

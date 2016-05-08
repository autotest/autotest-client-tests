# $Id$

use strict;
use warnings;

use Test::More tests => 12;

use XML::LibXML;

my $string = "<foo><bar/></foo>";

my $parser = XML::LibXML->new();

{
    my $doc = $parser->parse_string( $string );
    # TEST
    ok($doc, ' TODO : Add test name');
    local $XML::LibXML::skipXMLDeclaration = 1;
    # TEST
    is( $doc->toString(), $string, ' TODO : Add test name' );
    local $XML::LibXML::setTagCompression = 1;
    # TEST
    is( $doc->toString(), "<foo><bar></bar></foo>", ' TODO : Add test name' );
}

{
    local $XML::LibXML::skipDTD = 1;
    $parser->expand_entities(0);
    my $doc = $parser->parse_file( "example/dtd.xml" );
    # TEST
    ok($doc, ' TODO : Add test name');
    my $test = "<?xml version=\"1.0\"?>\n<doc>This is a valid document &foo; !</doc>\n";
    # TEST
    is( $doc->toString, $test, ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( $string );
    # TEST
    ok($doc, ' TODO : Add test name');
    my $dclone = $doc->cloneNode(1); # deep
    # TEST
    ok( ! $dclone->isSameNode($doc), ' TODO : Add test name' );
    # TEST
    ok( $dclone->getDocumentElement(), ' TODO : Add test name' );
    # TEST
    ok( $doc->toString() eq $dclone->toString(), ' TODO : Add test name' );

    my $clone = $doc->cloneNode(); # shallow
    # TEST
    ok( ! $clone->isSameNode($doc), ' TODO : Add test name' );
    # TEST
    ok( ! $clone->getDocumentElement(), ' TODO : Add test name' );
    $doc->getDocumentElement()->unbindNode();
    # TEST
    ok( $doc->toString() eq $clone->toString(), ' TODO : Add test name' );
}

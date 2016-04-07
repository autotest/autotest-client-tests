# $Id$

##
# this test checks the DOM Characterdata interface of XML::LibXML

use strict;
use warnings;

use Test::More tests => 36;

use XML::LibXML;

my $doc = XML::LibXML::Document->new();

{
    # 1. creation
    my $foo = "foobar";
    my $textnode = $doc->createTextNode($foo);
    # TEST
    ok( $textnode, 'creation 1');
    # TEST
    is( $textnode->nodeName(), '#text',  'creation 2');
    # TEST
    is( $textnode->nodeValue(), $foo,  'creation 3',);

    # 2. substring
    my $tnstr = $textnode->substringData( 1,2 );
    # TEST
    is( $tnstr , "oo", 'substring 1');
    # TEST
    is( $textnode->nodeValue(), $foo,  'substring 2' );

    # 3. Expansion
    $textnode->appendData( $foo );
    # TEST
    is( $textnode->nodeValue(), $foo . $foo, 'expansion 1');

    $textnode->insertData( 6, "FOO" );
    # TEST
    is( $textnode->nodeValue(), $foo."FOO".$foo, 'expansion 2' );

    $textnode->setData( $foo );
    $textnode->insertData( 6, "FOO" );
    # TEST
    is( $textnode->nodeValue(), $foo."FOO", 'expansion 3');
    $textnode->setData( $foo );
    $textnode->insertData( 3, "" );
    # TEST
    is( $textnode->nodeValue(), $foo, 'Empty insertion does not change value');

    # 4. Removal
    $textnode->deleteData( 1,2 );
    # TEST
    is( $textnode->nodeValue(), "fbar", 'Removal 1');
    $textnode->setData( $foo );
    $textnode->deleteData( 1,10 );
    # TEST
    is( $textnode->nodeValue(), "f", 'Removal 2');
    $textnode->setData( $foo );
    $textnode->deleteData( 10,1 );
    # TEST
    is( $textnode->nodeValue(), $foo, 'Removal 3');
    $textnode->deleteData( 1,0 );
    # TEST
    is( $textnode->nodeValue(), $foo, 'Removal 4');
    $textnode->deleteData( 0,0 );
    # TEST
    is( $textnode->nodeValue(), $foo, 'Removal 5');
    $textnode->deleteData( 0,2 );
    # TEST
    is( $textnode->nodeValue(), "obar", 'Removal 6');

    # 5. Replacement
    $textnode->setData( "test" );
    $textnode->replaceData( 1,2, "phish" );
    # TEST
    is( $textnode->nodeValue(), "tphisht", 'Replacement 1');
    $textnode->setData( "test" );
    $textnode->replaceData( 1,4, "phish" );
    # TEST
    is( $textnode->nodeValue(), "tphish",  'Replacement 2');
    $textnode->setData( "test" );
    $textnode->replaceData( 1,0, "phish" );
    # TEST
    is( $textnode->nodeValue(), "tphishest",  'Replacement 3');


    # 6. XML::LibXML features
    $textnode->setData( "test" );

    $textnode->replaceDataString( "es", "new" );
    # TEST
    is( $textnode->nodeValue(), "tnewt", 'replaceDataString() 1');

    $textnode->replaceDataRegEx( 'n(.)w', '$1s' );
    # TEST
    is( $textnode->nodeValue(), "test", 'replaceDataRegEx() 2');

    $textnode->setData( "blue phish, white phish, no phish" );
    $textnode->replaceDataRegEx( 'phish', 'test' );
    # TEST
    is( $textnode->nodeValue(), "blue test, white phish, no phish",
        'replaceDataRegEx 3',);

    # replace them all!
    $textnode->replaceDataRegEx( 'phish', 'test', 'g' );
    # TEST
    is( $textnode->nodeValue(), "blue test, white test, no test",
        'replaceDataRegEx g',);

    # check if special chars are encoded properly
    $textnode->setData( "te?st" );
    $textnode->replaceDataString( "e?s", 'ne\w' );
    # TEST
    is( $textnode->nodeValue(), 'tne\wt', ' TODO : Add test name' );

    # check if "." is encoded properly
    $textnode->setData( "h.thrt");
    $textnode->replaceDataString( "h.t", 'new', 1 );
    # TEST
    is( $textnode->nodeValue(), 'newhrt', ' TODO : Add test name' );

    # check if deleteDataString does not delete dots.
    $textnode->setData( 'hitpit' );
    $textnode->deleteDataString( 'h.t' );
    # TEST
    is( $textnode->nodeValue(), 'hitpit', ' TODO : Add test name' );

    # check if deleteDataString works
    $textnode->setData( 'hitpithit' );
    $textnode->deleteDataString( 'hit' );
    # TEST
    is( $textnode->nodeValue(), 'pithit', ' TODO : Add test name' );

    # check if deleteDataString all works
    $textnode->setData( 'hitpithit' );
    $textnode->deleteDataString( 'hit', 1 );
    # TEST
    is( $textnode->nodeValue(), 'pit', ' TODO : Add test name' );

    # check if entities don't get translated
    $textnode->setData(q(foo&amp;bar));
    # TEST
    is ( $textnode->getData(), q(foo&amp;bar), ' TODO : Add test name' );
}

{
    # standalone test
    my $node = XML::LibXML::Text->new("foo");
    # TEST
    ok($node, ' TODO : Add test name');
    # TEST
    is($node->nodeValue, "foo", ' TODO : Add test name' );
}

{
    # CDATA node name test

    my $node = XML::LibXML::CDATASection->new("test");

    # TEST
    is( $node->string_value(), "test", ' TODO : Add test name' );
    # TEST
    is( $node->nodeName(), "#cdata-section", ' TODO : Add test name' );
}

{
    # Comment node name test

    my $node = XML::LibXML::Comment->new("test");

    # TEST
    is( $node->string_value(), "test", ' TODO : Add test name' );
    # TEST
    is( $node->nodeName(), "#comment", ' TODO : Add test name' );
}

{
    # Document node name test

    my $node = XML::LibXML::Document->new();

    # TEST
    is( $node->nodeName(), "#document", ' TODO : Add test name' );
}
{
    # Document fragment node name test

    my $node = XML::LibXML::DocumentFragment->new();

    # TEST
    is( $node->nodeName(), "#document-fragment", ' TODO : Add test name' );
}

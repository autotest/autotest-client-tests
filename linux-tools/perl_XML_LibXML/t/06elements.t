# $Id$

##
# this test checks the DOM element and attribute interface of XML::LibXML

use strict;
use warnings;

# Should be 187.
use Test::More tests => 191;

use XML::LibXML;

my $foo       = "foo";
my $bar       = "bar";
my $nsURI     = "http://foo";
my $prefix    = "x";
my $attname1  = "A";
my $attvalue1 = "a";
my $attname2  = "B";
my $attvalue2 = "b";
my $attname3  = "C";

# TEST:$badnames=4;
my @badnames= ("1A", "<><", "&", "-:");

# 1. bound node
{
    my $doc = XML::LibXML::Document->new();
    my $elem = $doc->createElement( $foo );
    # TEST
    ok($elem, ' TODO : Add test name');
    # TEST
    is($elem->tagName, $foo, ' TODO : Add test name');

    {
        foreach my $name ( @badnames ) {
            eval { $elem->setNodeName( $name ); };
            # TEST*$badnames
            ok( $@, "setNodeName throws an exception for $name" );
        }
    }

    $elem->setAttribute( $attname1, $attvalue1 );
    # TEST
    ok( $elem->hasAttribute($attname1), ' TODO : Add test name' );
    # TEST
    is( $elem->getAttribute($attname1), $attvalue1, ' TODO : Add test name');

    my $attr = $elem->getAttributeNode($attname1);
    # TEST
    ok($attr, ' TODO : Add test name');
    # TEST
    is($attr->name, $attname1, ' TODO : Add test name');
    # TEST
    is($attr->value, $attvalue1, ' TODO : Add test name');

    $elem->setAttribute( $attname1, $attvalue2 );
    # TEST
    is($elem->getAttribute($attname1), $attvalue2, ' TODO : Add test name');
    # TEST
    is($attr->value, $attvalue2, ' TODO : Add test name');

    my $attr2 = $doc->createAttribute($attname2, $attvalue1);
    # TEST
    ok($attr2, ' TODO : Add test name');

    $elem->setAttributeNode($attr2);
    # TEST
    ok($elem->hasAttribute($attname2), ' TODO : Add test name' );
    # TEST
    is($elem->getAttribute($attname2),$attvalue1, ' TODO : Add test name');

    my $tattr = $elem->getAttributeNode($attname2);
    # TEST
    ok($tattr->isSameNode($attr2), ' TODO : Add test name');

    $elem->setAttribute($attname2, "");
    # TEST
    ok($elem->hasAttribute($attname2), ' TODO : Add test name' );
    # TEST
    is($elem->getAttribute($attname2), "", ' TODO : Add test name');

    $elem->setAttribute($attname3, "");
    # TEST
    ok($elem->hasAttribute($attname3), ' TODO : Add test name' );
    # TEST
    is($elem->getAttribute($attname3), "", ' TODO : Add test name');

    {
        foreach my $name ( @badnames ) {
            eval {$elem->setAttribute( $name, "X" );};
            # TEST*$badnames
            ok( $@, "setAttribute throws an exxception for '$name'" );
        }

    }


    # 1.1 Namespaced Attributes

    $elem->setAttributeNS( $nsURI, $prefix . ":". $foo, $attvalue2 );
    # TEST
    ok( $elem->hasAttributeNS( $nsURI, $foo ), ' TODO : Add test name' );
    # TEST
    ok( ! $elem->hasAttribute( $foo ), ' TODO : Add test name' );
    # TEST
    ok( $elem->hasAttribute( $prefix.":".$foo ), ' TODO : Add test name' );
    # warn $elem->toString() , "\n";
    $tattr = $elem->getAttributeNodeNS( $nsURI, $foo );
    # TEST
    ok($tattr, ' TODO : Add test name');
    # TEST
    is($tattr->name, $foo, ' TODO : Add test name');
    # TEST
    is($tattr->nodeName, $prefix .":".$foo, ' TODO : Add test name');
    # TEST
    is($tattr->value, $attvalue2, ' TODO : Add test name' );

    $elem->removeAttributeNode( $tattr );
    # TEST
    ok( !$elem->hasAttributeNS($nsURI, $foo), ' TODO : Add test name' );


    # empty NS
    $elem->setAttributeNS( '', $foo, $attvalue2 );
    # TEST
    ok( $elem->hasAttribute( $foo ), ' TODO : Add test name' );
    $tattr = $elem->getAttributeNode( $foo );
    # TEST
    ok($tattr, ' TODO : Add test name');
    # TEST
    is($tattr->name, $foo, ' TODO : Add test name');
    # TEST
    is($tattr->nodeName, $foo, ' TODO : Add test name');
    # TEST
    ok(!defined($tattr->namespaceURI), ' TODO : Add test name');
    # TEST
    is($tattr->value, $attvalue2, ' TODO : Add test name' );

    # TEST

    ok($elem->hasAttribute($foo) == 1, ' TODO : Add test name');
    # TEST
    ok($elem->hasAttributeNS(undef, $foo) == 1, ' TODO : Add test name');
    # TEST
    ok($elem->hasAttributeNS('', $foo) == 1, ' TODO : Add test name');

    $elem->removeAttributeNode( $tattr );
    # TEST
    ok( !$elem->hasAttributeNS('', $foo), ' TODO : Add test name' );
    # TEST
    ok( !$elem->hasAttributeNS(undef, $foo), ' TODO : Add test name' );

    # node based functions
    my $e2 = $doc->createElement($foo);
    $doc->setDocumentElement($e2);
    my $nsAttr = $doc->createAttributeNS( $nsURI.".x", $prefix . ":". $foo, $bar);
    # TEST
    ok( $nsAttr, ' TODO : Add test name' );
    $elem->setAttributeNodeNS($nsAttr);
    # TEST
    ok( $elem->hasAttributeNS($nsURI.".x", $foo), ' TODO : Add test name' );
    $elem->removeAttributeNS( $nsURI.".x", $foo);
    # TEST
    ok( !$elem->hasAttributeNS($nsURI.".x", $foo), ' TODO : Add test name' );

    # warn $elem->toString;
    $elem->setAttributeNS( $nsURI, $prefix . ":". $attname1, $attvalue2 );
    # warn $elem->toString;


    $elem->removeAttributeNS("",$attname1);
    # warn $elem->toString;

    # TEST

    ok( ! $elem->hasAttribute($attname1), ' TODO : Add test name' );
    # TEST
    ok( $elem->hasAttributeNS($nsURI,$attname1), ' TODO : Add test name' );
    # warn $elem->toString;

    {
        foreach my $name ( @badnames ) {
            eval {$elem->setAttributeNS( undef, $name, "X" );};
            # TEST*$badnames
            ok( $@, "setAttributeNS throws an exception for '$name'");
        }
    }
}

# 2. unbound node
{
    my $elem = XML::LibXML::Element->new($foo);
    # TEST
    ok($elem, ' TODO : Add test name');
    # TEST
    is($elem->tagName, $foo, ' TODO : Add test name');

    $elem->setAttribute( $attname1, $attvalue1 );
    # TEST
    ok( $elem->hasAttribute($attname1), ' TODO : Add test name' );
    # TEST
    is( $elem->getAttribute($attname1), $attvalue1, ' TODO : Add test name');

    my $attr = $elem->getAttributeNode($attname1);
    # TEST
    ok($attr, ' TODO : Add test name');
    # TEST
    is($attr->name, $attname1, ' TODO : Add test name');
    # TEST
    is($attr->value, $attvalue1, ' TODO : Add test name');

    $elem->setAttributeNS( $nsURI, $prefix . ":". $foo, $attvalue2 );
    # TEST
    ok( $elem->hasAttributeNS( $nsURI, $foo ), ' TODO : Add test name' );
    # warn $elem->toString() , "\n";
    my $tattr = $elem->getAttributeNodeNS( $nsURI, $foo );
    # TEST
    ok($tattr, ' TODO : Add test name');
    # TEST
    is($tattr->name, $foo, ' TODO : Add test name');
    # TEST
    is($tattr->nodeName, $prefix .":".$foo, ' TODO : Add test name');
    # TEST
    is($tattr->value, $attvalue2, ' TODO : Add test name' );

    $elem->removeAttributeNode( $tattr );
    # TEST
    ok( !$elem->hasAttributeNS($nsURI, $foo), ' TODO : Add test name' );
    # warn $elem->toString() , "\n";
}

# 3. Namespace handling
# 3.1 Namespace switching
{
    my $elem = XML::LibXML::Element->new($foo);
    # TEST
    ok($elem, ' TODO : Add test name');

    my $doc = XML::LibXML::Document->new();
    my $e2 = $doc->createElement($foo);
    $doc->setDocumentElement($e2);
    my $nsAttr = $doc->createAttributeNS( $nsURI, $prefix . ":". $foo, $bar);
    # TEST
    ok( $nsAttr, ' TODO : Add test name' );

    $elem->setAttributeNodeNS($nsAttr);
    # TEST
    ok( $elem->hasAttributeNS($nsURI, $foo), ' TODO : Add test name' );

    # TEST
    ok( ! defined $nsAttr->ownerDocument, ' TODO : Add test name');
    # warn $elem->toString() , "\n";
}

# 3.2 default Namespace and Attributes
{
    my $doc  = XML::LibXML::Document->new();
    my $elem = $doc->createElementNS( "foo", "root" );
    $doc->setDocumentElement( $elem );

    $elem->setNamespace( "foo", "bar" );

    $elem->setAttributeNS( "foo", "x:attr",  "test" );
    $elem->setAttributeNS( undef, "attr2",  "test" );

    # TEST

    is( $elem->getAttributeNS( "foo", "attr" ), "test", ' TODO : Add test name' );
    # TEST
    is( $elem->getAttributeNS( "", "attr2" ), "test", ' TODO : Add test name' );

    # warn $doc->toString;
    # actually this doesn't work correctly with libxml2 <= 2.4.23
    $elem->setAttributeNS( "foo", "attr2",  "bar" );
    # TEST
    is( $elem->getAttributeNS( "foo", "attr2" ), "bar", ' TODO : Add test name' );
    # warn $doc->toString;
}

# 4. Text Append and Normalization
# 4.1 Normalization on an Element node
{
    my $doc = XML::LibXML::Document->new();
    my $t1 = $doc->createTextNode( "bar1" );
    my $t2 = $doc->createTextNode( "bar2" );
    my $t3 = $doc->createTextNode( "bar3" );
    my $e  = $doc->createElement("foo");
    my $e2 = $doc->createElement("bar");
    $e->appendChild( $e2 );
    $e->appendChild( $t1 );
    $e->appendChild( $t2 );
    $e->appendChild( $t3 );

    my @cn = $e->childNodes;

    # this is the correct behaviour for DOM. the nodes are still
    # referred
    # TEST
    is( scalar( @cn ), 4, ' TODO : Add test name' );

    $e->normalize;

    @cn = $e->childNodes;
    # TEST
    is( scalar( @cn ), 2, ' TODO : Add test name' );

    # TEST

    ok(! defined $t2->parentNode, ' TODO : Add test name');
    # TEST
    ok(! defined $t3->parentNode, ' TODO : Add test name');
}

# 4.2 Normalization on a Document node
{
    my $doc = XML::LibXML::Document->new();
    my $t1 = $doc->createTextNode( "bar1" );
    my $t2 = $doc->createTextNode( "bar2" );
    my $t3 = $doc->createTextNode( "bar3" );
    my $e  = $doc->createElement("foo");
    my $e2 = $doc->createElement("bar");
    $doc->setDocumentElement($e);
    $e->appendChild( $e2 );
    $e->appendChild( $t1 );
    $e->appendChild( $t2 );
    $e->appendChild( $t3 );

    my @cn = $e->childNodes;

    # this is the correct behaviour for DOM. the nodes are still
    # referred
    # TEST
    is( scalar( @cn ), 4, ' TODO : Add test name' );

    $doc->normalize;

    @cn = $e->childNodes;
    # TEST
    is( scalar( @cn ), 2, ' TODO : Add test name' );

    # TEST

    ok(! defined $t2->parentNode, ' TODO : Add test name');
    # TEST
    ok(! defined $t3->parentNode, ' TODO : Add test name');
}


# 5. XML::LibXML extensions
{
    my $plainstring = "foo";
    my $stdentstring= "$foo & this";

    my $doc = XML::LibXML::Document->new();
    my $elem = $doc->createElement( $foo );
    $doc->setDocumentElement( $elem );

    $elem->appendText( $plainstring );
    # TEST
    is( $elem->string_value , $plainstring, ' TODO : Add test name' );

    $elem->appendText( $stdentstring );
    # TEST
    is( $elem->string_value , $plainstring.$stdentstring, ' TODO : Add test name' );

    $elem->appendTextChild( "foo");
    $elem->appendTextChild( "foo" => "foo&bar" );

    my @cn = $elem->childNodes;
    # TEST
    ok( scalar(@cn), ' TODO : Add test name' );
    # TEST
    is( scalar(@cn), 3, ' TODO : Add test name' );
    # TEST
    ok( !$cn[1]->hasChildNodes, ' TODO : Add test name');
    # TEST
    ok( $cn[2]->hasChildNodes, ' TODO : Add test name');
}

# 6. XML::LibXML::Attr nodes
{
    my $dtd = <<'EOF';
<!DOCTYPE root [
<!ELEMENT root EMPTY>
<!ATTLIST root fixed CDATA  #FIXED "foo">
<!ATTLIST root a:ns_fixed CDATA  #FIXED "ns_foo">
<!ATTLIST root name NMTOKEN #IMPLIED>
<!ENTITY ent "ENT">
]>
EOF
    my $ns = q(urn:xx);
    my $xml_nons = qq(<root foo="&quot;bar&ent;&quot;" xmlns:a="$ns"/>);
    my $xml_ns = qq(<root xmlns="$ns" xmlns:a="$ns" foo="&quot;bar&ent;&quot;"/>);

    # TEST:$xml=2;
    for my $xml ($xml_nons, $xml_ns) {
        my $parser = new XML::LibXML;
        $parser->complete_attributes(0);
        $parser->expand_entities(0);
        my $doc = $parser->parse_string($dtd.$xml);

        # TEST*$xml

        ok ($doc, ' TODO : Add test name');
        my $root = $doc->getDocumentElement;
        {
            my $attr = $root->getAttributeNode('foo');
            # TEST*$xml
            ok ($attr, ' TODO : Add test name');
            # TEST*$xml
            is (ref($attr), 'XML::LibXML::Attr', ' TODO : Add test name');
            # TEST*$xml
            ok ($root->isSameNode($attr->ownerElement), ' TODO : Add test name');
            # TEST*$xml
            is ($attr->value, '"barENT"', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->serializeContent, '&quot;bar&ent;&quot;', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->toString, ' foo="&quot;bar&ent;&quot;"', ' TODO : Add test name');
        }
        {
            my $attr = $root->getAttributeNodeNS(undef,'foo');
            # TEST*$xml
            ok ($attr, ' TODO : Add test name');
            # TEST*$xml
            is (ref($attr), 'XML::LibXML::Attr', ' TODO : Add test name');
            # TEST*$xml
            ok ($root->isSameNode($attr->ownerElement), ' TODO : Add test name');
            # TEST*$xml
            is ($attr->value, '"barENT"', ' TODO : Add test name');
        }
        # fixed values are defined
        # TEST*$xml
        is ($root->getAttribute('fixed'),'foo', ' TODO : Add test name');

        SKIP:
        {
            if (XML::LibXML::LIBXML_VERSION() < 20627)
            {
                skip('skipping for libxml2 < 2.6.27', 1);
            }
            # TEST*$xml
            is($root->getAttributeNS($ns,'ns_fixed'),'ns_foo', 'ns_fixed is ns_foo')
        }

        # TEST*$xml
        is ($root->getAttribute('a:ns_fixed'),'ns_foo', ' TODO : Add test name');

        # TEST*$xml

        is ($root->hasAttribute('fixed'),0, ' TODO : Add test name');
        # TEST*$xml
        is ($root->hasAttributeNS($ns,'ns_fixed'),0, ' TODO : Add test name');
        # TEST*$xml
        is ($root->hasAttribute('a:ns_fixed'),0, ' TODO : Add test name');


        # but no attribute nodes correspond to them
        # TEST*$xml
        ok (!defined $root->getAttributeNode('a:ns_fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNode('fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNode('name'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNode('baz'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS($ns,'foo'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS($ns,'fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS($ns,'ns_fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS(undef,'fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS(undef,'name'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS(undef,'baz'), ' TODO : Add test name');
    }

    # TEST:$xml=2;
    {
    my @names = ("nons", "ns");
    for my $xml ($xml_nons, $xml_ns) {
        my $n = shift(@names);
        my $parser = new XML::LibXML;
        $parser->complete_attributes(1);
        $parser->expand_entities(1);
        my $doc = $parser->parse_string($dtd.$xml);
        # TEST*$xml
        ok ($doc, "Could parse document $n");
        my $root = $doc->getDocumentElement;
        {
            my $attr = $root->getAttributeNode('foo');
            # TEST*$xml
            ok ($attr, "Attribute foo exists for $n");
            # TEST*$xml
            isa_ok ($attr, 'XML::LibXML::Attr',
                "Attribute is of type XML::LibXML::Attr - $n");
            # TEST*$xml
            ok ($root->isSameNode($attr->ownerElement),
                "attr owner element is root - $n");
            # TEST*$xml
            is ($attr->value, q{"barENT"},
                "attr value is OK - $n");
            # TEST*$xml
            is ($attr->serializeContent,
                '&quot;barENT&quot;',
                "serializeContent - $n");
            # TEST*$xml
            is ($attr->toString, ' foo="&quot;barENT&quot;"',
                "toString - $n");
        }
        # fixed values are defined
        # TEST*$xml
        is ($root->getAttribute('fixed'),'foo', ' TODO : Add test name');
        # TEST*$xml
        is ($root->getAttributeNS($ns,'ns_fixed'),'ns_foo', ' TODO : Add test name');
        # TEST*$xml
        is ($root->getAttribute('a:ns_fixed'),'ns_foo', ' TODO : Add test name');

        # and attribute nodes are created
        {
            my $attr = $root->getAttributeNode('fixed');
            # TEST*$xml
            is (ref($attr), 'XML::LibXML::Attr', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->value,'foo', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->toString, ' fixed="foo"', ' TODO : Add test name');
        }
        {
            my $attr = $root->getAttributeNode('a:ns_fixed');
            # TEST*$xml
            is (ref($attr), 'XML::LibXML::Attr', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->value,'ns_foo', ' TODO : Add test name');
        }
        {
            my $attr = $root->getAttributeNodeNS($ns,'ns_fixed');
            # TEST*$xml
            is (ref($attr), 'XML::LibXML::Attr', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->value,'ns_foo', ' TODO : Add test name');
            # TEST*$xml
            is ($attr->toString, ' a:ns_fixed="ns_foo"', ' TODO : Add test name');
        }

        # TEST*$xml

        ok (!defined $root->getAttributeNode('ns_fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNode('name'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNode('baz'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS($ns,'foo'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS($ns,'fixed'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS(undef,'name'), ' TODO : Add test name');
        # TEST*$xml
        ok (!defined $root->getAttributeNodeNS(undef,'baz'), ' TODO : Add test name');
    }
    }
}

# -*- cperl -*-
# $Id$

##
# this test checks the DOM Node interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

# since all tests are run on a preparsed

# Should be 166.
use Test::More tests => 194;

use XML::LibXML;
use XML::LibXML::Common qw(:libxml);
use strict;
use warnings;
my $xmlstring = q{<foo>bar<foobar/><bar foo="foobar"/><!--foo--><![CDATA[&foo bar]]></foo>};

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_string( $xmlstring );

# 1   Standalone Without NameSpaces
# 1.1 Node Attributes

{
    my $node = $doc->documentElement;
    my $rnode;

    # TEST

    ok($node, ' TODO : Add test name');
    # TEST
    is($node->nodeType, XML_ELEMENT_NODE, ' TODO : Add test name');
    # TEST
    is($node->nodeName, "foo", ' TODO : Add test name');
    # TEST
    ok(!defined( $node->nodeValue ), ' TODO : Add test name');
    # TEST
    ok($node->hasChildNodes, ' TODO : Add test name');
    # TEST
    is($node->textContent, "bar&foo bar", ' TODO : Add test name');

    {
        my @children = $node->childNodes;
        # TEST
        is( scalar @children, 5, ' TODO : Add test name' );
        # TEST
        is( $children[0]->nodeType, XML_TEXT_NODE, ' TODO : Add test name' );
        # TEST
        is( $children[0]->nodeValue, "bar", ' TODO : Add test name' );
        # TEST
        is( $children[4]->nodeType, XML_CDATA_SECTION_NODE, ' TODO : Add test name' );
        # TEST
        is( $children[4]->nodeValue, "&foo bar", ' TODO : Add test name' );

        my $fc = $node->firstChild;
        # TEST
        ok( $fc, ' TODO : Add test name' );
        # TEST
        ok( $fc->isSameNode($children[0]), ' TODO : Add test name');
        # TEST
        ok( $fc->baseURI =~ /unknown-/, ' TODO : Add test name' );

        my $od = $fc->ownerDocument;
        # TEST
        ok( $od, ' TODO : Add test name' );
        # TEST
        ok( $od->isSameNode($doc), ' TODO : Add test name');

        my $xc = $fc->nextSibling;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc->isSameNode($children[1]), ' TODO : Add test name' );

        $fc = $node->lastChild;
        # TEST
        ok( $fc, ' TODO : Add test name' );
        # TEST
        ok( $fc->isSameNode($children[4]), ' TODO : Add test name');

        $xc = $fc->previousSibling;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc->isSameNode($children[3]), ' TODO : Add test name' );
        $rnode = $xc;

        $xc = $fc->parentNode;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc->isSameNode($node), ' TODO : Add test name' );

        $xc = $children[2];
        {
            # 1.2 Attribute Node
            # TEST
            ok( $xc->hasAttributes, ' TODO : Add test name' );
            my $attributes = $xc->attributes;
            # TEST
            ok( $attributes, ' TODO : Add test name' );
            # TEST
            is( ref($attributes), "XML::LibXML::NamedNodeMap", ' TODO : Add test name' );
            # TEST
            is( $attributes->length, 1, ' TODO : Add test name' );
            my $attr = $attributes->getNamedItem("foo");

            # TEST

            ok( $attr, ' TODO : Add test name' );
            # TEST
            is( $attr->nodeType, XML_ATTRIBUTE_NODE, ' TODO : Add test name' );
            # TEST
            is( $attr->nodeName, "foo", ' TODO : Add test name' );
            # TEST
            is( $attr->nodeValue, "foobar", ' TODO : Add test name' );
            # TEST
            is( $attr->hasChildNodes, 0, ' TODO : Add test name');
        }

        {
            my @attributes = $xc->attributes;
            # TEST
            is( scalar( @attributes ), 1, ' TODO : Add test name' );
        }

        # 1.2 Node Cloning
        {
            my $cnode  = $doc->createElement("foo");
	    $cnode->setAttribute('aaa','AAA');
	    $cnode->setAttributeNS('http://ns','x:bbb','BBB');
            my $c1node = $doc->createElement("bar");
            $cnode->appendChild( $c1node );

            my $xnode = $cnode->cloneNode(0);
            # TEST
            ok( $xnode, ' TODO : Add test name' );
            # TEST
            is( $xnode->nodeName, "foo", ' TODO : Add test name' );
            # TEST
            ok( ! $xnode->hasChildNodes, ' TODO : Add test name' );
	    # TEST
	    is( $xnode->getAttribute('aaa'),'AAA', ' TODO : Add test name' );
	    # TEST
	    is( $xnode->getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            $xnode = $cnode->cloneNode(1);
            # TEST
            ok( $xnode, ' TODO : Add test name' );
            # TEST
            is( $xnode->nodeName, "foo", ' TODO : Add test name' );
            # TEST
            ok( $xnode->hasChildNodes, ' TODO : Add test name' );
	    # TEST
	    is( $xnode->getAttribute('aaa'),'AAA', ' TODO : Add test name' );
	    # TEST
	    is( $xnode->getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            my @cn = $xnode->childNodes;
            # TEST
            ok( @cn, ' TODO : Add test name' );
            # TEST
            is( scalar(@cn), 1, ' TODO : Add test name');
            # TEST
            is( $cn[0]->nodeName, "bar", ' TODO : Add test name' );
            # TEST
            ok( !$cn[0]->isSameNode( $c1node ), ' TODO : Add test name' );

            # clone namespaced elements
            my $nsnode = $doc->createElementNS( "fooNS", "foo:bar" );

            my $cnsnode = $nsnode->cloneNode(0);
            # TEST
            is( $cnsnode->nodeName, "foo:bar", ' TODO : Add test name' );
            # TEST
            ok( $cnsnode->localNS(), ' TODO : Add test name' );
            # TEST
            is( $cnsnode->namespaceURI(), 'fooNS', ' TODO : Add test name' );

            # clone namespaced elements (recursive)
            my $c2nsnode = $nsnode->cloneNode(1);
            # TEST
            is( $c2nsnode->toString(), $nsnode->toString(), ' TODO : Add test name' );
        }

        # 1.3 Node Value
        my $string2 = "<foo>bar<tag>foo</tag></foo>";
        {
            my $doc2 = $parser->parse_string( $string2 );
            my $root = $doc2->documentElement;
            # TEST
            ok( ! defined($root->nodeValue), ' TODO : Add test name' );
            # TEST
            is( $root->textContent, "barfoo", ' TODO : Add test name');
        }
    }

    {
        my $children = $node->childNodes;
        # TEST
        ok( defined $children, ' TODO : Add test name' );
        # TEST
        is( ref($children), "XML::LibXML::NodeList", ' TODO : Add test name' );
    }

    # 2. (Child) Node Manipulation

    # 2.1 Valid Operations

    {
        # 2.1.1 Single Node

        my $inode = $doc->createElement("kungfoo"); # already tested
        my $jnode = $doc->createElement("kungfoo");
        my $xn = $node->insertBefore($inode, $rnode);
        # TEST
        ok( $xn, ' TODO : Add test name' );
        # TEST
        ok( $xn->isSameNode($inode), ' TODO : Add test name' );


        $node->insertBefore( $jnode, undef );
        my @ta  = $node->childNodes();
        $xn = pop @ta;
        # TEST
        ok( $xn->isSameNode( $jnode ), ' TODO : Add test name' );
        $jnode->unbindNode;

        my @cn = $node->childNodes;
        # TEST
        is(scalar(@cn), 6, ' TODO : Add test name');
        # TEST
        ok( $cn[3]->isSameNode($inode), ' TODO : Add test name' );

        $xn = $node->removeChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($inode), ' TODO : Add test name');

        @cn = $node->childNodes;
        # TEST
        is(scalar(@cn), 5, ' TODO : Add test name');
        # TEST
        ok( $cn[3]->isSameNode($rnode), ' TODO : Add test name' );

        $xn = $node->appendChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($inode), ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($node->lastChild), ' TODO : Add test name');

        $xn = $node->removeChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($inode), ' TODO : Add test name');
        # TEST
        ok($cn[-1]->isSameNode($node->lastChild), ' TODO : Add test name');

        $xn = $node->replaceChild( $inode, $rnode );
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($rnode), ' TODO : Add test name');

        my @cn2 = $node->childNodes;
        # TEST
        is(scalar(@cn), 5, ' TODO : Add test name');
        # TEST
        ok( $cn2[3]->isSameNode($inode), ' TODO : Add test name' );
    }

    {
        # insertAfter Tests
        my $anode = $doc->createElement("a");
        my $bnode = $doc->createElement("b");
        my $cnode = $doc->createElement("c");
        my $dnode = $doc->createElement("d");

        $anode->insertAfter( $bnode, undef );
        # TEST
        is( $anode->toString(), '<a><b/></a>', ' TODO : Add test name' );

        $anode->insertAfter( $dnode, undef );
        # TEST
        is( $anode->toString(), '<a><b/><d/></a>', ' TODO : Add test name' );

        $anode->insertAfter( $cnode, $bnode );
        # TEST
        is( $anode->toString(), '<a><b/><c/><d/></a>', ' TODO : Add test name' );

    }

    {
        my ($inode, $jnode );

        $inode = $doc->createElement("kungfoo"); # already tested
        $jnode = $doc->createElement("foobar");

        my $xn = $inode->insertBefore( $jnode, undef);
        # TEST
        ok( $xn, ' TODO : Add test name' );
        # TEST
        ok( $xn->isSameNode( $jnode ), ' TODO : Add test name' );
    }

    {
        # 2.1.2 Document Fragment

        my @cn   = $doc->documentElement->childNodes;
        my $rnode= $doc->documentElement;

        my $frag = $doc->createDocumentFragment;
        my $node1= $doc->createElement("kung");
        my $node2= $doc->createElement("foo");

        $frag->appendChild($node1);
        $frag->appendChild($node2);

        my $xn = $node->appendChild( $frag );
        # TEST
        ok($xn, ' TODO : Add test name');
        my @cn2 = $node->childNodes;
        # TEST
        is(scalar(@cn2), 7, ' TODO : Add test name');
        # TEST
        ok($cn2[-1]->isSameNode($node2), ' TODO : Add test name');
        # TEST
        ok($cn2[-2]->isSameNode($node1), ' TODO : Add test name');

        $frag->appendChild( $node1 );
        $frag->appendChild( $node2 );

        @cn2 = $node->childNodes;
        # TEST
        is(scalar(@cn2), 5, ' TODO : Add test name');

        $xn = $node->replaceChild( $frag, $cn[3] );
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn->isSameNode($cn[3]), ' TODO : Add test name');
        @cn2 = $node->childNodes;
        # TEST
        is(scalar(@cn2), 6, ' TODO : Add test name');

        $frag->appendChild( $node1 );
        $frag->appendChild( $node2 );

        $xn = $node->insertBefore( $frag, $cn[0] );
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($node1->isSameNode($node->firstChild), ' TODO : Add test name');
        @cn2 = $node->childNodes;
        # TEST
        is(scalar(@cn2), 6, ' TODO : Add test name');
    }

    # 2.2 Invalid Operations


    # 2.3 DOM extensions
    {
        my $str = "<foo><bar/>com</foo>";
        my $doc = XML::LibXML->new->parse_string( $str );
        my $elem= $doc->documentElement;
        # TEST
        ok( $elem, ' TODO : Add test name' );
        # TEST
        ok( $elem->hasChildNodes, ' TODO : Add test name' );
        $elem->removeChildNodes;
        # TEST
        is( $elem->hasChildNodes,0, ' TODO : Add test name' );
        $elem->toString;
    }
}

# 3   Standalone With NameSpaces

{
    my $doc = XML::LibXML::Document->new();
    my $URI ="http://kungfoo";
    my $pre = "foo";
    my $name= "bar";

    my $elem = $doc->createElementNS($URI, $pre.":".$name);

    # TEST

    ok($elem, ' TODO : Add test name');
    # TEST
    is($elem->nodeName, $pre.":".$name, ' TODO : Add test name');
    # TEST
    is($elem->namespaceURI, $URI, ' TODO : Add test name');
    # TEST
    is($elem->prefix, $pre, ' TODO : Add test name');
    # TEST
    is($elem->localname, $name, ' TODO : Add test name' );

    # TEST

    is( $elem->lookupNamespacePrefix( $URI ), $pre, ' TODO : Add test name');
    # TEST
    is( $elem->lookupNamespaceURI( $pre ), $URI, ' TODO : Add test name');

    my @ns = $elem->getNamespaces;
    # TEST
    is( scalar(@ns) ,1, ' TODO : Add test name' );
}

# 4.   Document swtiching

{
    # 4.1 simple document
    my $docA = XML::LibXML::Document->new;
    {
        my $docB = XML::LibXML::Document->new;
        my $e1   = $docB->createElement( "A" );
        my $e2   = $docB->createElement( "B" );
        my $e3   = $docB->createElementNS( "http://kungfoo", "C:D" );
        $e1->appendChild( $e2 );
        $e1->appendChild( $e3 );

        $docA->setDocumentElement( $e1 );
    }
    my $elem = $docA->documentElement;
    my @c = $elem->childNodes;
    my $xroot = $c[0]->ownerDocument;
    # TEST
    ok( $xroot->isSameNode($docA), ' TODO : Add test name' );


}

# 5.   libxml2 specials

{
    my $docA = XML::LibXML::Document->new;
    my $e1   = $docA->createElement( "A" );
    my $e2   = $docA->createElement( "B" );
    my $e3   = $docA->createElement( "C" );

    $e1->appendChild( $e2 );
    my $x = $e2->replaceNode( $e3 );
    my @cn = $e1->childNodes;
    # TEST
    ok(@cn, ' TODO : Add test name');
    # TEST
    is( scalar(@cn), 1, ' TODO : Add test name' );
    # TEST
    ok($cn[0]->isSameNode($e3), ' TODO : Add test name');
    # TEST
    ok($x->isSameNode($e2), ' TODO : Add test name');

    $e3->addSibling( $e2 );
    @cn = $e1->childNodes;
    # TEST
    is( scalar(@cn), 2, ' TODO : Add test name' );
    # TEST
    ok($cn[0]->isSameNode($e3), ' TODO : Add test name');
    # TEST
    ok($cn[1]->isSameNode($e2), ' TODO : Add test name');
}

# 6.   implicit attribute manipulation

{
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_string( '<foo bar="foo"/>' );
    my $root = $doc->documentElement;
    my $attributes = $root->attributes;
    # TEST
    ok($attributes, ' TODO : Add test name');

    my $newAttr = $doc->createAttribute( "kung", "foo" );
    $attributes->setNamedItem( $newAttr );

    my @att = $root->attributes;
    # TEST
    ok(@att, ' TODO : Add test name');
    # TEST
    is(scalar(@att), 2, ' TODO : Add test name');
    $newAttr = $doc->createAttributeNS( "http://kungfoo", "x:kung", "foo" );

    $attributes->setNamedItem($newAttr);
    @att = $root->attributes;
    # TEST
    ok(@att, ' TODO : Add test name');
    # TEST
    is(scalar(@att), 4, ' TODO : Add test name'); # because of the namespace ...

    $newAttr = $doc->createAttributeNS( "http://kungfoo", "x:kung", "bar" );
    $attributes->setNamedItem($newAttr);
    @att = $root->attributes;
    # TEST
    ok(@att, ' TODO : Add test name');
    # TEST
    is(scalar(@att), 4, ' TODO : Add test name');
    # TEST
    ok($att[2]->isSameNode($newAttr), ' TODO : Add test name');

    $attributes->removeNamedItem("x:kung");

    @att = $root->attributes;
    # TEST
    ok(@att, ' TODO : Add test name');
    # TEST
    is(scalar(@att), 3, ' TODO : Add test name');
    # TEST
    is($attributes->length, 3, ' TODO : Add test name');
}

# 7. importing and adopting

{
    my $parser = XML::LibXML->new;
    my $doc1 = $parser->parse_string( "<foo>bar<foobar/></foo>" );
    my $doc2 = XML::LibXML::Document->new;

    # TEST

    ok( $doc1 && $doc2, ' TODO : Add test name' );
    my $rnode1 = $doc1->documentElement;
    # TEST
    ok( $rnode1, ' TODO : Add test name' );
    my $rnode2 = $doc2->importNode( $rnode1 );
    # TEST
    ok( ! $rnode2->isSameNode( $rnode1 ), ' TODO : Add test name' ) ;
    $doc2->setDocumentElement( $rnode2 );

    my $node = $rnode2->cloneNode(0);
    # TEST
    ok( $node, ' TODO : Add test name' );
    my $cndoc = $node->ownerDocument;
    # TEST
    ok( $cndoc, ' TODO : Add test name' );
    # TEST
    ok( $cndoc->isSameNode( $doc2 ), ' TODO : Add test name' );

    my $xnode = XML::LibXML::Element->new("test");

    my $node2 = $doc2->importNode($xnode);
    # TEST
    ok( $node2, ' TODO : Add test name' );
    my $cndoc2 = $node2->ownerDocument;
    # TEST
    ok( $cndoc2, ' TODO : Add test name' );
    # TEST
    ok( $cndoc2->isSameNode( $doc2 ), ' TODO : Add test name' );

    my $doc3 = XML::LibXML::Document->new;
    my $node3 = $doc3->adoptNode( $xnode );
    # TEST
    ok( $node3, ' TODO : Add test name' );
    # TEST
    ok( $xnode->isSameNode( $node3 ), ' TODO : Add test name' );
    # TEST
    ok( $doc3->isSameNode( $node3->ownerDocument ), ' TODO : Add test name' );

    my $xnode2 = XML::LibXML::Element->new("test");
    $xnode2->setOwnerDocument( $doc3 ); # alternate version of adopt node
    # TEST
    ok( $xnode2->ownerDocument, ' TODO : Add test name' );
    # TEST
    ok( $doc3->isSameNode( $xnode2->ownerDocument ), ' TODO : Add test name' );
}

{
  # appending empty fragment
  my $doc = XML::LibXML::Document->new();
  my $frag = $doc->createDocumentFragment();
  my $root = $doc->createElement( 'foo' );
  my $r = $root->appendChild( $frag );
  # TEST
  ok( $r, ' TODO : Add test name' );
}

{
   my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
   my $schema = $doc->createElement('sphinx:schema');
   eval { $schema->appendChild( $schema ) };
   # TEST
   like ($@, qr/HIERARCHY_REQUEST_ERR/,
       ' Thrown HIERARCHY_REQUEST_ERR exception'
   );
}

{
   my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
   my $attr = $doc->createAttribute('test','bar');
   my $ent = $doc->createEntityReference('foo');
   my $text = $doc->createTextNode('baz');
   $attr->appendChild($ent);
   $attr->appendChild($text);
   # TEST
   ok($attr->toString() eq ' test="bar&foo;baz"', ' TODO : Add test name');
}

{
    my $string = <<'EOF';
<r>
  <a/>
	  <b/>
  <![CDATA[

  ]]>
  <!-- foo -->
  <![CDATA[
    x
  ]]>
  <?foo bar?>
  <c/>
  text
</r>
EOF

    # TEST:$count=2;
    foreach my $arg_to_parse ($string, \$string)
    {
        my $doc = XML::LibXML->load_xml(string=>$arg_to_parse);
        my $r = $doc->getDocumentElement;
        # TEST*$count
        ok($r, ' TODO : Add test name');
        my @nonblank = $r->nonBlankChildNodes;
        # TEST*$count
        is(join(',',map $_->nodeName,@nonblank), 'a,b,#comment,#cdata-section,foo,c,#text', ' TODO : Add test name' );
        # TEST*$count
        is($r->firstChild->nodeName, '#text', ' TODO : Add test name');

        my @all = $r->childNodes;
        # TEST*$count
        is(join(',',map $_->nodeName,@all), '#text,a,#text,b,#text,#cdata-section,#text,#comment,#text,#cdata-section,#text,foo,#text,c,#text', ' TODO : Add test name' );

        my $f = $r->firstNonBlankChild;
        my $p;
        # TEST*$count
        is($f->nodeName, 'a', ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        is($f->previousSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( !$f->previousNonBlankSibling, ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        is($f->nodeName, 'b', ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        ok($f->isa('XML::LibXML::Comment'), ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        ok($f->isa('XML::LibXML::CDATASection'), ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        ok($f->isa('XML::LibXML::PI'), ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        is($f->nodeName, 'c', ' TODO : Add test name');
        # TEST*$count
        is($f->nextSibling->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f->nextNonBlankSibling;
        # TEST*$count
        is($f->nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        is($f->nodeValue, "\n  text\n", ' TODO : Add test name');
        # TEST*$count
        ok(!$f->nextSibling, ' TODO : Add test name');
        # TEST*$count
        ok( $f->previousNonBlankSibling->isSameNode($p), ' TODO : Add test name' );

        $f=$f->nextNonBlankSibling;
        # TEST*$count
        ok(!defined $f, ' TODO : Add test name');

    }
}


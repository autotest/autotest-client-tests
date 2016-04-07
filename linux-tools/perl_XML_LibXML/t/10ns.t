# -*- cperl -*-

use strict;
use warnings;

# Should be 129.
use Test::More tests => 129;

use XML::LibXML;
use XML::LibXML::Common qw(:libxml);

my $parser = XML::LibXML->new();

my $xml1 = <<EOX;
<a xmlns:b="http://whatever"
><x b:href="out.xml"
/><b:c/></a>
EOX

my $xml2 = <<EOX;
<a xmlns:b="http://whatever" xmlns:c="http://kungfoo"
><x b:href="out.xml"
/><b:c/><c:b/></a>
EOX

my $xml3 = <<EOX;
<a xmlns:b="http://whatever">
    <x b:href="out.xml"/>
    <x>
    <c:b xmlns:c="http://kungfoo">
        <c:d/>
    </c:b>
    </x>
    <x>
    <c:b xmlns:c="http://foobar">
        <c:d/>
    </c:b>
    </x>
</a>
EOX

print "# 1.   single namespace \n";

{
    my $doc1 = $parser->parse_string( $xml1 );
    my $elem = $doc1->documentElement;
    # TEST
    is($elem->lookupNamespaceURI( "b" ), "http://whatever", ' TODO : Add test name' );
    my @cn = $elem->childNodes;
    # TEST
    is($cn[0]->lookupNamespaceURI( "b" ), "http://whatever", ' TODO : Add test name' );
    # TEST
    is($cn[1]->namespaceURI, "http://whatever", ' TODO : Add test name' );
}

print "# 2.    multiple namespaces \n";

{
    my $doc2 = $parser->parse_string( $xml2 );

    my $elem = $doc2->documentElement;
    # TEST
    is($elem->lookupNamespaceURI( "b" ), "http://whatever", ' TODO : Add test name');
    # TEST
    is($elem->lookupNamespaceURI( "c" ), "http://kungfoo", ' TODO : Add test name');
    my @cn = $elem->childNodes;

    # TEST

    is($cn[0]->lookupNamespaceURI( "b" ), "http://whatever", ' TODO : Add test name' );
    # TEST
    is($cn[0]->lookupNamespaceURI( "c" ), "http://kungfoo", ' TODO : Add test name');

    # TEST

    is($cn[1]->namespaceURI, "http://whatever", ' TODO : Add test name' );
    # TEST
    is($cn[2]->namespaceURI, "http://kungfoo", ' TODO : Add test name' );
}

print "# 3.   nested names \n";

{
    my $doc3 = $parser->parse_string( $xml3 );
    my $elem = $doc3->documentElement;
    my @cn = $elem->childNodes;
    my @xs = grep { $_->nodeType == XML_ELEMENT_NODE } @cn;

    my @x1 = $xs[1]->childNodes; my @x2 = $xs[2]->childNodes;

    # TEST

    is( $x1[1]->namespaceURI , "http://kungfoo", ' TODO : Add test name' );
    # TEST
    is( $x2[1]->namespaceURI , "http://foobar", ' TODO : Add test name' );

    # namespace scopeing
    # TEST
    ok( !defined($elem->lookupNamespacePrefix( "http://kungfoo" )), ' TODO : Add test name' );
    # TEST
    ok( !defined($elem->lookupNamespacePrefix( "http://foobar" )), ' TODO : Add test name' );
}

print "# 4. post creation namespace setting\n";
{
    my $e1 = XML::LibXML::Element->new("foo");
    my $e2 = XML::LibXML::Element->new("bar:foo");
    my $e3 = XML::LibXML::Element->new("foo");
    $e3->setAttribute( "kung", "foo" );
    my $a = $e3->getAttributeNode("kung");

    $e1->appendChild($e2);
    $e2->appendChild($e3);
    # TEST
    ok( $e2->setNamespace("http://kungfoo", "bar"), ' TODO : Add test name' );
    # TEST
    ok( $a->setNamespace("http://kungfoo", "bar"), ' TODO : Add test name' );
    # TEST
    is( $a->nodeName, "bar:kung", ' TODO : Add test name' );
}

print "# 5. importing namespaces\n";

{

    my $doca = XML::LibXML->createDocument;
    my $docb = XML::LibXML->new()->parse_string( <<EOX );
<x:a xmlns:x="http://foo.bar"><x:b/></x:a>
EOX

    my $b = $docb->documentElement->firstChild;

    my $c = $doca->importNode( $b );

    my @attra = $c->attributes;
    # TEST
    is( scalar(@attra), 1, ' TODO : Add test name' );
    # TEST
    is( $attra[0]->nodeType, 18, ' TODO : Add test name' );
    my $d = $doca->adoptNode($b);

    # TEST

    ok( $d->isSameNode( $b ), ' TODO : Add test name' );
    my @attrb = $d->attributes;
    # TEST
    is( scalar(@attrb), 1, ' TODO : Add test name' );
    # TEST
    is( $attrb[0]->nodeType, 18, ' TODO : Add test name' );
}

print "# 6. lossless setting of namespaces with setAttribute\n";
# reported by Kurt George Gjerde
{
    my $doc = XML::LibXML->createDocument;
    my $root = $doc->createElementNS('http://example.com', 'document');
    $root->setAttribute('xmlns:xxx', 'http://example.com');
    $root->setAttribute('xmlns:yyy', 'http://yonder.com');
    $doc->setDocumentElement( $root );

    my $strnode = $root->toString();
    # TEST
    ok ( $strnode =~ /xmlns:xxx/ and $strnode =~ /xmlns=/, ' TODO : Add test name' );
}

print "# 7. namespaced attributes\n";
{
    my $doc = XML::LibXML->new->parse_string(<<'EOF');
<test xmlns:xxx="http://example.com"/>
EOF
    my $root = $doc->getDocumentElement();
    # namespaced attributes
    $root->setAttribute('xxx:attr', 'value');
    # TEST
    ok ( $root->getAttributeNode('xxx:attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xxx:attr'), 'value', ' TODO : Add test name' );
    print $root->toString(1),"\n";
    # TEST
    ok ( $root->getAttributeNodeNS('http://example.com','attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNS('http://example.com','attr'), 'value', ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNode('xxx:attr')->getNamespaceURI(), 'http://example.com', ' TODO : Add test name');

    #change encoding to UTF-8 and retest
    $doc->setEncoding('UTF-8');
    # namespaced attributes
    $root->setAttribute('xxx:attr', 'value');
    # TEST
    ok ( $root->getAttributeNode('xxx:attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xxx:attr'), 'value', ' TODO : Add test name' );
    print $root->toString(1),"\n";
    # TEST
    ok ( $root->getAttributeNodeNS('http://example.com','attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNS('http://example.com','attr'), 'value', ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNode('xxx:attr')->getNamespaceURI(),
        'http://example.com', ' TODO : Add test name');
}

print "# 8. changing namespace declarations\n";
{
    my $xmlns = 'http://www.w3.org/2000/xmlns/';

    my $doc = XML::LibXML->createDocument;
    my $root = $doc->createElementNS('http://example.com', 'document');
    $root->setAttributeNS($xmlns, 'xmlns:xxx', 'http://example.com');
    $root->setAttribute('xmlns:yyy', 'http://yonder.com');
    $doc->setDocumentElement( $root );

    # can we get the namespaces ?
    # TEST
    is ( $root->getAttribute('xmlns:xxx'), 'http://example.com', ' TODO : Add test name');
    # TEST
    is ( $root->getAttributeNS($xmlns,'xmlns'), 'http://example.com', ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xmlns:yyy'), 'http://yonder.com', ' TODO : Add test name');
    # TEST
    is ( $root->lookupNamespacePrefix('http://yonder.com'), 'yyy', ' TODO : Add test name');
    # TEST
    is ( $root->lookupNamespaceURI('yyy'), 'http://yonder.com', ' TODO : Add test name');

    # can we change the namespaces ?
    # TEST
    ok ( $root->setAttribute('xmlns:yyy', 'http://newyonder.com'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xmlns:yyy'), 'http://newyonder.com', ' TODO : Add test name');
    # TEST
    is ( $root->lookupNamespacePrefix('http://newyonder.com'), 'yyy', ' TODO : Add test name');
    # TEST
    is ( $root->lookupNamespaceURI('yyy'), 'http://newyonder.com', ' TODO : Add test name');

    # can we change the default namespace ?
    $root->setAttribute('xmlns', 'http://other.com' );
    # TEST
    is ( $root->getAttribute('xmlns'), 'http://other.com', ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespacePrefix('http://other.com'), "", ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(''), 'http://other.com', ' TODO : Add test name' );

    # non-existent namespaces
    # TEST
    is ( $root->lookupNamespaceURI('foo'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespacePrefix('foo'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xmlns:foo'), undef, ' TODO : Add test name' );

    # changing namespace declaration URI and prefix
    # TEST
    ok ( $root->setNamespaceDeclURI('yyy', 'http://changed.com'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xmlns:yyy'), 'http://changed.com', ' TODO : Add test name');
    # TEST
    is ( $root->lookupNamespaceURI('yyy'), 'http://changed.com', ' TODO : Add test name');
    eval { $root->setNamespaceDeclPrefix('yyy','xxx'); };
    # TEST
    ok ( $@, ' TODO : Add test name' );  # prefix occupied
    eval { $root->setNamespaceDeclPrefix('yyy',''); };
    # TEST
    ok ( $@, ' TODO : Add test name' );  # prefix occupied
    # TEST
    ok ( $root->setNamespaceDeclPrefix('yyy', 'zzz'), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('yyy'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('zzz'), 'http://changed.com', ' TODO : Add test name' );
    # TEST
    ok ( $root->setNamespaceDeclURI('zzz',undef ), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('zzz'), undef, ' TODO : Add test name' );

    my $strnode = $root->toString();
    # TEST
    ok ( $strnode !~ /xmlns:zzz/, ' TODO : Add test name' );

    # changing the default namespace declaration
    # TEST
    ok ( $root->setNamespaceDeclURI('','http://test'), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(''), 'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->getNamespaceURI(), 'http://test', ' TODO : Add test name' );

    # changing prefix of the default ns declaration
    # TEST
    ok ( $root->setNamespaceDeclPrefix('','foo'), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(''), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('foo'), 'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->getNamespaceURI(),  'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->prefix(),  'foo', ' TODO : Add test name' );

    # turning a ns declaration to a default ns declaration
    # TEST
    ok ( $root->setNamespaceDeclPrefix('foo',''), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('foo'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(''), 'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(undef), 'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->getNamespaceURI(),  'http://test', ' TODO : Add test name' );
    # TEST
    is ( $root->prefix(),  undef, ' TODO : Add test name' );

    # removing the default ns declaration
    # TEST
    ok ( $root->setNamespaceDeclURI('',undef), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI(''), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->getNamespaceURI(), undef, ' TODO : Add test name' );

    $strnode = $root->toString();
    # TEST
    ok ( $strnode !~ /xmlns=/, ' TODO : Add test name' );

    # namespaced attributes
    $root->setAttribute('xxx:attr', 'value');
    # TEST
    ok ( $root->getAttributeNode('xxx:attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('xxx:attr'), 'value', ' TODO : Add test name' );
    print $root->toString(1),"\n";
    # TEST
    ok ( $root->getAttributeNodeNS('http://example.com','attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNS('http://example.com','attr'), 'value', ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNode('xxx:attr')->getNamespaceURI(), 'http://example.com', ' TODO : Add test name');

    # removing other xmlns declarations
    $root->addNewChild('http://example.com', 'xxx:foo');
    # TEST
    ok( $root->setNamespaceDeclURI('xxx',undef), ' TODO : Add test name' );
    # TEST
    is ( $root->lookupNamespaceURI('xxx'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->getNamespaceURI(), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->firstChild->getNamespaceURI(), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->prefix(),  undef, ' TODO : Add test name' );
    # TEST
    is ( $root->firstChild->prefix(),  undef, ' TODO : Add test name' );


    print $root->toString(1),"\n";
    # check namespaced attributes
    # TEST
    is ( $root->getAttributeNode('xxx:attr'), undef, ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNodeNS('http://example.com', 'attr'), undef, ' TODO : Add test name' );
    # TEST
    ok ( $root->getAttributeNode('attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttribute('attr'), 'value', ' TODO : Add test name' );
    # TEST
    ok ( $root->getAttributeNodeNS(undef,'attr'), ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNS(undef,'attr'), 'value', ' TODO : Add test name' );
    # TEST
    is ( $root->getAttributeNode('attr')->getNamespaceURI(), undef, ' TODO : Add test name');


    $strnode = $root->toString();
    # TEST
    ok ( $strnode !~ /xmlns=/, ' TODO : Add test name' );
    # TEST
    ok ( $strnode !~ /xmlns:xxx=/, ' TODO : Add test name' );
    # TEST
    ok ( $strnode =~ /<foo/, ' TODO : Add test name' );

    # TEST

    ok ( $root->setNamespaceDeclPrefix('xxx',undef), ' TODO : Add test name' );

    # TEST

    is ( $doc->findnodes('/document/foo')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $doc->findnodes('/document[foo]')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $doc->findnodes('/document[*]')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $doc->findnodes('/document[@attr and foo]')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $doc->findvalue('/document/@attr'), 'value', ' TODO : Add test name' );

    my $xp = XML::LibXML::XPathContext->new($doc);
    # TEST
    is ( $xp->findnodes('/document/foo')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $xp->findnodes('/document[foo]')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $xp->findnodes('/document[*]')->size(), 1, ' TODO : Add test name' );

    # TEST

    is ( $xp->findnodes('/document[@attr and foo]')->size(), 1, ' TODO : Add test name' );
    # TEST
    is ( $xp->findvalue('/document/@attr'), 'value', ' TODO : Add test name' );

    # TEST

    is ( $root->firstChild->prefix(),  undef, ' TODO : Add test name' );
}

print "# 9. namespace reconciliation\n";
{
    my $doc = XML::LibXML->createDocument( 'http://default', 'root' );
    my $root = $doc->documentElement;
    $root->setNamespace( 'http://children', 'child', 0 );

    $root->appendChild( my $n = $doc->createElementNS( 'http://default', 'branch' ));
    # appending an element in the same namespace will
    # strip its declaration
    # TEST
    ok( !defined($n->getAttribute( 'xmlns' )), ' TODO : Add test name' );

    $n->appendChild( my $a = $doc->createElementNS( 'http://children', 'child:a' ));
    $n->appendChild( my $b = $doc->createElementNS( 'http://children', 'child:b' ));

    $n->appendChild( my $c = $doc->createElementNS( 'http://children', 'child:c' ));
    # appending $c strips the declaration
    # TEST
    ok( !defined($c->getAttribute('xmlns:child')), ' TODO : Add test name' );

    # add another prefix for children
    $c->setAttribute( 'xmlns:foo', 'http://children' );
    # TEST
    is( $c->getAttribute( 'xmlns:foo' ), 'http://children', ' TODO : Add test name' );

    $n->appendChild( my $d = $doc->createElementNS( 'http://other', 'branch' ));
    # appending an element with a new default namespace
    # will leave it declared
    # TEST
    is( $d->getAttribute( 'xmlns' ), 'http://other', ' TODO : Add test name' );

    my $doca = XML::LibXML->createDocument( 'http://default/', 'root' );
    $doca->adoptNode( $a );
    $doca->adoptNode( $b );
    $doca->documentElement->appendChild( $a );
    $doca->documentElement->appendChild( $b );

    # Because the child namespace isn't defined in $doca
    # it should get declared on both child nodes $a and $b
    # TEST
    is( $a->getAttribute( 'xmlns:child' ), 'http://children', ' TODO : Add test name' );
    # TEST
    is( $b->getAttribute( 'xmlns:child' ), 'http://children', ' TODO : Add test name' );

    $doca = XML::LibXML->createDocument( 'http://children', 'child:root' );
    $doca->adoptNode( $a );
    $doca->documentElement->appendChild( $a );

    # $doca declares the child namespace, so the declaration
    # should now get stripped from $a
    # TEST
    ok( !defined($a->getAttribute( 'xmlns:child' )), ' TODO : Add test name' );

    $doca->documentElement->removeChild( $a );

    # $a should now have its namespace re-declared
    # TEST
    is( $a->getAttribute( 'xmlns:child' ), 'http://children', ' TODO : Add test name' );

    $doca->documentElement->appendChild( $a );

    # $doca declares the child namespace, so the declaration
    # should now get stripped from $a
    # TEST
    ok( !defined($a->getAttribute( 'xmlns:child' )), ' TODO : Add test name' );


    $doc = XML::LibXML::Document->new;
    $n = $doc->createElement( 'didl' );
    $n->setAttribute( "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance" );

    $a = $doc->createElement( 'dc' );
    $a->setAttribute( "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance" );
    $a->setAttribute( "xsi:schemaLocation"=>"http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives
.org/OAI/2.0/oai_dc.xsd" );

    $n->appendChild( $a );

    # the declaration for xsi should be stripped
    # TEST
    ok( !defined($a->getAttribute( 'xmlns:xsi' )), ' TODO : Add test name' );

    $n->removeChild( $a );

    # should be a new declaration for xsi in $a
    # TEST
    is( $a->getAttribute( 'xmlns:xsi' ), 'http://www.w3.org/2001/XMLSchema-instance', ' TODO : Add test name' );

    $b = $doc->createElement( 'foo' );
    $b->setAttribute( 'xsi:bar', 'bar' );
    $n->appendChild( $b );
    $n->removeChild( $b );

    # a prefix without a namespace can't be reliably compared,
    # so $b doesn't acquire a declaration from $n!
    # TEST
    ok( !defined($b->getAttribute( 'xmlns:xsi' )), ' TODO : Add test name' );

    # tests for reconciliation during setAttributeNodeNS
    my $attr = $doca->createAttributeNS(
        'http://children', 'child:attr','value'
    );
    # TEST
    ok($attr, ' TODO : Add test name');
    my $child= $doca->documentElement->firstChild;
    # TEST
    ok($child, ' TODO : Add test name');
    $child->setAttributeNodeNS($attr);
    # TEST
    ok ( !defined($child->getAttribute( 'xmlns:child' )), ' TODO : Add test name' );

    # due to libxml2 limitation, XML::LibXML declares the namespace
    # on the root element
    $attr = $doca->createAttributeNS('http://other','other:attr','value');
    # TEST
    ok($attr, ' TODO : Add test name');
    $child->setAttributeNodeNS($attr);
    #
    # TEST
    ok ( !defined($child->getAttribute( 'xmlns:other' )), ' TODO : Add test name' );
    # TEST
    ok ( defined($doca->documentElement->getAttribute( 'xmlns:other' )), ' TODO : Add test name' );
}

print "# 10. xml namespace\n";
{
    my $docOne = XML::LibXML->new->parse_string(
        '<foo><inc xml:id="test"/></foo>'
    );
    my $docTwo = XML::LibXML->new->parse_string(
        '<bar><urgh xml:id="foo"/></bar>'
    );

    my $inc = $docOne->getElementById('test');
    my $rep = $docTwo->getElementById('foo');
    $inc->parentNode->replaceChild($rep, $inc);
    # TEST
    is($inc->getAttributeNS('http://www.w3.org/XML/1998/namespace','id'),'test', ' TODO : Add test name');
    # TEST
    ok($inc->isSameNode($docOne->getElementById('test')), ' TODO : Add test name');
}

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use XML::LibXML;

{
    if (XML::LibXML::LIBXML_VERSION() >= 20623) {
        plan tests => 42;
    }
    else {
        plan skip_all => 'Skipping ID tests on libxml2 <= 2.6.23';
    }
}

my $parser = XML::LibXML->new;

my $xml1 = <<'EOF';
<!DOCTYPE root [
<!ELEMENT root (root?)>
<!ATTLIST root id ID #REQUIRED
               notid CDATA #IMPLIED
>
]>
<root id="foo" notid="x"/>
EOF

my $xml2 = <<'EOF';
<root2 xml:id="foo"/>
EOF

sub _debug {
  my ($msg,$n)=@_;
  print "$msg\t$$n\n'",(ref $n ? $n->toString : "NULL"),"'\n";
}

# TEST:$do_validate=2;
for my $do_validate (0..1) {
  my ($n,$doc,$root,$at);
  # TEST*$do_validate
  ok( $doc = $parser->parse_string($xml1), ' TODO : Add test name' );
  $root = $doc->getDocumentElement;
  $n = $doc->getElementById('foo');
  # TEST*$do_validate
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );

  # old name
  $n = $doc->getElementsById('foo');
  # TEST*$do_validate
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );

  $at = $n->getAttributeNode('id');
  # TEST*$do_validate
  ok( $at, ' TODO : Add test name' );
  # TEST*$do_validate
  ok( $at->isId, ' TODO : Add test name' );

  $at = $root->getAttributeNode('notid');
  # TEST*$do_validate
  ok( $at->isId == 0, ' TODO : Add test name' );

  # _debug("1: foo: ",$n);
  $doc->getDocumentElement->setAttribute('id','bar');
  # TEST
  ok( $doc->validate, ' TODO : Add test name' ) if $do_validate;
  $n = $doc->getElementById('bar');
  # TEST*$do_validate
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );

  # _debug("1: bar: ",$n);
  $n = $doc->getElementById('foo');
  # TEST*$do_validate
  ok( !defined($n), ' TODO : Add test name' );
  # _debug("1: !foo: ",$n);

  my $test = $doc->createElement('root');
  $root->appendChild($test);
  $test->setAttribute('id','new');
  # TEST
  ok( $doc->validate, ' TODO : Add test name' ) if $do_validate;
  $n = $doc->getElementById('new');
  # TEST*$do_validate
  ok( $test->isSameNode( $n ), ' TODO : Add test name' );

  $at = $n->getAttributeNode('id');
  # TEST*$do_validate
  ok( $at, ' TODO : Add test name' );
  # TEST*$do_validate
  ok( $at->isId, ' TODO : Add test name' );
  # _debug("1: new: ",$n);
}

{
  my ($n,$doc,$root,$at);
  # TEST
  ok( $doc = $parser->parse_string($xml2), ' TODO : Add test name' );
  $root = $doc->getDocumentElement;

  $n = $doc->getElementById('foo');
  # TEST
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );
  # _debug("1: foo: ",$n);

  $doc->getDocumentElement->setAttribute('xml:id','bar');
  $n = $doc->getElementById('foo');
  # TEST
  ok( !defined($n), ' TODO : Add test name' );
  # _debug("1: !foo: ",$n);

  $n = $doc->getElementById('bar');
  # TEST
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );

  $at = $n->getAttributeNode('xml:id');
  # TEST
  ok( $at, ' TODO : Add test name' );
  # TEST
  ok( $at->isId, ' TODO : Add test name' );

  $n->setAttribute('id','FOO');
  # TEST
  ok( $at->isSameNode($n->getAttributeNode('xml:id')), ' TODO : Add test name' );

  $at = $n->getAttributeNode('id');
  # TEST
  ok( $at, ' TODO : Add test name' );
  # TEST
  ok( ! $at->isId, ' TODO : Add test name' );

  $at = $n->getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
  # TEST
  ok( $at, ' TODO : Add test name' );
  # TEST
  ok( $at->isId, ' TODO : Add test name' );
  # _debug("1: bar: ",$n);

  $doc->getDocumentElement->setAttributeNS('http://www.w3.org/XML/1998/namespace','id','baz');
  $n = $doc->getElementById('bar');
  # TEST
  ok( !defined($n), ' TODO : Add test name' );
  # _debug("1: !bar: ",$n);

  $n = $doc->getElementById('baz');
  # TEST
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );
  # _debug("1: baz: ",$n);
  $at = $n->getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
  # TEST
  ok( $at, ' TODO : Add test name' );
  # TEST
  ok( $at->isId, ' TODO : Add test name' );

  $doc->getDocumentElement->setAttributeNS('http://www.w3.org/XML/1998/namespace','xml:id','bag');
  $n = $doc->getElementById('baz');
  # TEST
  ok( !defined($n), ' TODO : Add test name' );
  # _debug("1: !baz: ",$n);

  $n = $doc->getElementById('bag');
  # TEST
  ok( $root->isSameNode( $n ), ' TODO : Add test name' );
  # _debug("1: bag: ",$n);

  $n->removeAttribute('id');
  # TEST
  is( $root->toString, '<root2 xml:id="bag"/>', ' TODO : Add test name' );
}

1;

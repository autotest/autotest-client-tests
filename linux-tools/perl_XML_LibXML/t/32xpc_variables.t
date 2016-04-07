# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 35;

use XML::LibXML;
use XML::LibXML::XPathContext;

my $doc = XML::LibXML->new->parse_string(<<'XML');
<foo><bar a="b">Bla</bar><bar/></foo>
XML

my %variables = (
	'a' => XML::LibXML::Number->new(2),
	'b' => "b",
	);

sub get_variable {
  my ($data, $name, $uri)=@_;
  return exists($data->{$name}) ? $data->{$name} : undef;
}

# $c: nodelist
$variables{c} = XML::LibXML::XPathContext->new($doc)->findnodes('//bar');
# TEST
ok($variables{c}->isa('XML::LibXML::NodeList'), ' TODO : Add test name');
# TEST
ok($variables{c}->size() == 2, ' TODO : Add test name');
# TEST
ok($variables{c}->get_node(1)->nodeName eq 'bar', ' TODO : Add test name');

# $d: a single element node
$variables{d} = XML::LibXML::XPathContext->new($doc)->findnodes('/*')->pop;
# TEST
ok($variables{d}->nodeName() eq 'foo', ' TODO : Add test name');

# $e: a single text node
$variables{e} = XML::LibXML::XPathContext->new($doc)->findnodes('//text()');
# TEST
ok($variables{e}->get_node(1)->data() eq 'Bla', ' TODO : Add test name');

# $f: a single attribute node
$variables{f} = XML::LibXML::XPathContext->new($doc)->findnodes('//@*')->pop;
# TEST
ok($variables{f}->nodeName() eq 'a', ' TODO : Add test name');
# TEST
ok($variables{f}->value() eq 'b', ' TODO : Add test name');

# $f: a single document node
$variables{g} = XML::LibXML::XPathContext->new($doc)->findnodes('/')->pop;
# TEST
ok($variables{g}->nodeType() == XML::LibXML::XML_DOCUMENT_NODE, ' TODO : Add test name');

# test registerVarLookupFunc() and getVarLookupData()
my $xc = XML::LibXML::XPathContext->new($doc);
# TEST
ok(!defined($xc->getVarLookupData), ' TODO : Add test name');
$xc->registerVarLookupFunc(\&get_variable,\%variables);
# TEST
ok(defined($xc->getVarLookupData), ' TODO : Add test name');
my $h1=$xc->getVarLookupData;
my $h2=\%variables;
# TEST
ok("$h1" eq "$h2", ' TODO : Add test name' );
# TEST
ok($h1 eq $xc->getVarLookupData, ' TODO : Add test name');
# TEST
ok(\&get_variable eq $xc->getVarLookupFunc, ' TODO : Add test name');

# test values returned by XPath queries
# TEST
ok($xc->find('$a') == 2, ' TODO : Add test name');
# TEST
ok($xc->find('$b') eq "b", ' TODO : Add test name');
# TEST
ok($xc->findnodes('//@a[.=$b]')->size() == 1, ' TODO : Add test name');
# TEST
ok($xc->findnodes('//@a[.=$b]')->size() == 1, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$c')->size() == 2, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$c')->size() == 2, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$c[1]')->pop->isSameNode($variables{c}->get_node(1)), ' TODO : Add test name');
# TEST
ok($xc->findnodes('$c[@a="b"]')->size() == 1, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$d')->size() == 1, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$d/*')->size() == 2, ' TODO : Add test name');
# TEST
ok($xc->findnodes('$d')->pop->isSameNode($variables{d}), ' TODO : Add test name');
# TEST
ok($xc->findvalue('$e') eq 'Bla', ' TODO : Add test name');
# TEST
ok($xc->findnodes('$e')->pop->isSameNode($variables{e}->get_node(1)), ' TODO : Add test name');
# TEST
ok($xc->findnodes('$c[@*=$f]')->size() == 1, ' TODO : Add test name');
# TEST
ok($xc->findvalue('$f') eq 'b', ' TODO : Add test name');
# TEST
ok($xc->findnodes('$f')->pop->nodeName eq 'a', ' TODO : Add test name');
# TEST
ok($xc->findnodes('$f')->pop->isSameNode($variables{f}), ' TODO : Add test name');
# TEST
ok($xc->findnodes('$g')->pop->isSameNode($variables{g}), ' TODO : Add test name');

# unregiser variable lookup
$xc->unregisterVarLookupFunc();
eval { $xc->find('$a') };
# TEST
ok($@, ' TODO : Add test name');
# TEST
ok(!defined($xc->getVarLookupFunc()), ' TODO : Add test name');

my $foo='foo';
$xc->registerVarLookupFunc(sub {},$foo);
# TEST
ok($xc->getVarLookupData eq 'foo', ' TODO : Add test name');
$foo=undef;
# TEST
ok($xc->getVarLookupData eq 'foo', ' TODO : Add test name');


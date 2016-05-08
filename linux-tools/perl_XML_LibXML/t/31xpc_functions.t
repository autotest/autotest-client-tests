# -*- cperl -*-

use strict;
use warnings;

use Test::More  tests => 32;

use XML::LibXML;
use XML::LibXML::XPathContext;

my $doc = XML::LibXML->new->parse_string(<<'XML');
<foo><bar a="b">Bla</bar><bar/></foo>
XML
# TEST
ok($doc, ' TODO : Add test name');

my $xc = XML::LibXML::XPathContext->new($doc);
$xc->registerNs('foo','urn:foo');

$xc->registerFunctionNS('copy','urn:foo',
			sub { @_==1 ? $_[0] : die "too many parameters"}
		       );

# copy string, real, integer, nodelist
# TEST
ok($xc->findvalue('foo:copy("bar")') eq 'bar', ' TODO : Add test name');
# TEST

ok($xc->findvalue('foo:copy(3.14)') < 3.141, ' TODO : Add test name'); # can't use == here because of
# TEST

ok($xc->findvalue('foo:copy(3.14)') > 3.139, ' TODO : Add test name'); # float math
# TEST

ok($xc->findvalue('foo:copy(7)') == 7, ' TODO : Add test name');
# TEST

ok($xc->find('foo:copy(//*)')->size() == 3, ' TODO : Add test name');
my ($foo)=$xc->findnodes('(//*)[2]');
# TEST

ok($xc->findnodes('foo:copy(//*)[2]')->pop->isSameNode($foo), ' TODO : Add test name');

# too many arguments
eval { $xc->findvalue('foo:copy(1,xyz)') };
# TEST

ok ($@, ' TODO : Add test name');

# without a namespace
$xc->registerFunction('dummy', sub { 'DUMMY' });
# TEST

ok($xc->findvalue('dummy()') eq 'DUMMY', ' TODO : Add test name');

# unregister it
$xc->unregisterFunction('dummy');
eval { $xc->findvalue('dummy()') };
# TEST

ok ($@, ' TODO : Add test name');

# retister by name
sub dummy2 { 'DUMMY2' };
$xc->registerFunction('dummy2', 'dummy2');
# TEST

ok($xc->findvalue('dummy2()') eq 'DUMMY2', ' TODO : Add test name');

# unregister
$xc->unregisterFunction('dummy2');
eval { $xc->findvalue('dummy2()') };
# TEST

ok ($@, ' TODO : Add test name');


# a mix of different arguments types
$xc->registerFunction('join',
    sub { join shift,
          map { (ref($_)&&$_->isa('XML::LibXML::Node')) ? $_->nodeName : $_ }
          map { (ref($_)&&$_->isa('XML::LibXML::NodeList')) ? @$_ : $_ }
	  @_
	});

# TEST

ok($xc->findvalue('join("","a","b","c")') eq 'abc', ' TODO : Add test name');
# TEST

ok($xc->findvalue('join("-","a",/foo,//*)') eq 'a-foo-foo-bar-bar', ' TODO : Add test name');
# TEST

ok($xc->findvalue('join("-",foo:copy(//*))') eq 'foo-bar-bar', ' TODO : Add test name');

# unregister foo:copy
$xc->unregisterFunctionNS('copy','urn:foo');
eval { $xc->findvalue('foo:copy("bar")') };
# TEST

ok ($@, ' TODO : Add test name');

# test context reentrance
$xc->registerFunction('test-lock1', sub { $xc->find('string(//node())') });
$xc->registerFunction('test-lock2', sub { $xc->findnodes('//bar') });
# TEST

ok($xc->find('test-lock1()') eq $xc->find('string(//node())'), ' TODO : Add test name');
# TEST

ok($xc->find('count(//bar)=2'), ' TODO : Add test name');
# TEST

ok($xc->find('count(test-lock2())=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc->find('count(test-lock2()|//bar)=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc->findnodes('test-lock2()[2]')->pop()->isSameNode($xc->findnodes('//bar[2]')), ' TODO : Add test name');

$xc->registerFunction('test-lock3', sub { $xc->findnodes('test-lock2(//bar)') });
# TEST

ok($xc->find('count(test-lock2())=count(test-lock3())'), ' TODO : Add test name');
# TEST

ok($xc->find('count(test-lock3())=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc->find('count(test-lock3()|//bar)=count(//bar)'), ' TODO : Add test name');

# function creating new nodes
$xc->registerFunction('new-foo',
		      sub {
			return $doc->createElement('foo');
		      });
# TEST

ok($xc->findnodes('new-foo()')->pop()->nodeName eq 'foo', ' TODO : Add test name');
my ($test_node) = $xc->findnodes('new-foo()');

$xc->registerFunction('new-chunk',
		      sub {
			XML::LibXML->new->parse_string('<x><y><a/><a/></y><y><a/></y></x>')->find('//a')
		      });
# TEST

ok($xc->findnodes('new-chunk()')->size() == 3, ' TODO : Add test name');
my ($x)=$xc->findnodes('new-chunk()/parent::*');
# TEST

ok($x->nodeName() eq 'y', ' TODO : Add test name');
# TEST

ok($xc->findvalue('name(new-chunk()/parent::*)') eq 'y', ' TODO : Add test name');
# TEST

ok($xc->findvalue('count(new-chunk()/parent::*)=2'), ' TODO : Add test name');

my $largedoc=XML::LibXML->new->parse_string('<a>'.('<b/>' x 3000).'</a>');
$xc->setContextNode($largedoc);
$xc->registerFunction('pass1',
			sub {
			  [$largedoc->findnodes('(//*)')]
			});
$xc->registerFunction('pass2',sub { $_[0] } );
$xc->registerVarLookupFunc( sub { [$largedoc->findnodes('(//*)')] }, undef);
$largedoc->toString();

# TEST

ok($xc->find('$a[name()="b"]')->size()==3000, ' TODO : Add test name');
my @pass1=$xc->findnodes('pass1()');
# TEST

ok(@pass1==3001, ' TODO : Add test name');
# TEST

ok($xc->find('pass2(//*)')->size()==3001, ' TODO : Add test name');

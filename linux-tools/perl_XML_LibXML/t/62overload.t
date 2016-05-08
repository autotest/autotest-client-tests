# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 12;

use XML::LibXML;

my $e1 = XML::LibXML::Element->new('test1');
$e1->setAttribute('attr' => 'value1');

my $e2 = XML::LibXML::Element->new('test2');
$e2->setAttribute('attr' => 'value2');

my $h1 = \%{ $e1 };
my $h2 = \%{ $e2 };

isnt $h1,$h2, 'different references';

is $h1->{attr}, 'value1', 'affr for el 1';
is $h2->{attr}, 'value2', 'affr for el 2';

is "$e1", '<test1 attr="value1"/>', 'stringify for el 1';
is "$e2", '<test2 attr="value2"/>', 'stringify for el 2';

cmp_ok 0+$e1, '>', 1, 'num for el 1';
cmp_ok 0+$e2, '>', 1, 'num for el 2';

isnt 0+$e1,0+$e2, 'num for e1 and e2 differs';

my $e3 = $e1;

ok $e3 eq $e1, 'eq';
ok $e3 == $e1, '==';

ok $e1 ne $e2, 'ne';
ok $e1 != $e2, '!=';

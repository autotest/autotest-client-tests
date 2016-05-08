use strict;
use warnings;
use Test::More tests => 25;
use XML::LibXML;

my $root = XML::LibXML->load_xml( IO => \*DATA )->documentElement;

# TEST
ok(
    tied %$root,
    'elements can be hash dereffed to a tied hash',
    );

# TEST
isa_ok(
    tied %$root,
    'XML::LibXML::AttributeHash',
    'tied %$element',
    );

# TEST
ok(
    exists $root->{'attr1'},
    'EXISTS non-namespaced',
    );

# TEST
is(
    $root->{'attr1'},
    'foo',
    'FETCH non-namespaced',
    );

$root->{attr1} = 'bar';
# TEST
is(
    $root->getAttribute('attr1'),
    'bar',
    'STORE non-namespaced',
    );

$root->{attr11} = 'baz';
# TEST
is(
    $root->getAttribute('attr11'),
    'baz',
    'STORE (and create) non-namespaced',
    );

delete $root->{attr11};
# TEST
ok(
    !$root->hasAttribute('attr11'),
    'DELETE non-namespaced',
    );

my $fail = 1;
while (my ($k, $v) = each %$root)
{
    if ($k eq 'attr1')
    {
        $fail = 0;
        # TEST
        pass('FIRSTKEY/NEXTKEY non-namespaced');
    }
}

if ($fail)
{
    fail('FIRSTKEY/NEXTKEY non-namespaced');
}

# TEST
ok(
    exists $root->{'{http://localhost/}attr2'},
    'EXISTS namespaced',
    );

# TEST
is(
    $root->{'{http://localhost/}attr2'},
    'bar',
    'FETCH namespaced',
    );

$root->{'{http://localhost/}attr2'} = 'quux';
# TEST
is(
    $root->getAttributeNS('http://localhost/', 'attr2'),
    'quux',
    'STORE namespaced',
    );

$root->{'{http://localhost/}attr22'} = 'quuux';
# TEST
is(
    $root->getAttributeNS('http://localhost/', 'attr22'),
    'quuux',
    'STORE (and create) namespaced',
    );

$root->{'{http://localhost/another}attr22'} = 'xyzzy';
# TEST
is(
    $root->getAttributeNS('http://localhost/another', 'attr22'),
    'xyzzy',
    'STORE (and create) namespaced, in new namespace',
    );

delete $root->{'{http://localhost/another}attr22'};
# TEST
ok(
    !$root->hasAttributeNS('http://localhost/another', 'attr22'),
    'DELETE namespaced',
    );

my $fail2 = 1;
while (my ($k, $v) = each %$root)
{
    if ($k eq '{http://localhost/}attr22')
    {
        $fail2 = 0;
        # TEST
        pass('FIRSTKEY/NEXTKEY namespaced');
    }
}

if ($fail2)
{
    fail('FIRSTKEY/NEXTKEY namespaced');
}

# TEST
like(
    $root->toStringEC14N,
    qr{<root xmlns:x="http://localhost/" attr1="bar" x:attr2="quux" x:attr22="quuux"></root>},
    '!!! toStringEC14N',
    );

# These are tests for:
# https://rt.cpan.org/Ticket/Display.html?id=75257
# https://rt.cpan.org/Ticket/Display.html?id=75293
# https://rt.cpan.org/Ticket/Display.html?id=75259
# (Three duplicate reports for the same problem.)

# TEST
is_deeply(
    [($root == $root)],
    [1],
    '== comparison',
);

# TEST
is_deeply(
    [($root eq $root)],
    [1],
    'eq comparison',
);

# TEST
is_deeply(
    [($root == 'not-root')],
    [''],
    '== negative comparison',
);

# TEST
is_deeply(
    [($root == 'not-root')],
    [''],
    '== negative comparison',
);

# TEST
is_deeply(
    [!($root != 'not-root')],
    [''],
    '!== negative comparison',
);

# TEST
is_deeply(
    [($root eq 'not-root')],
    [''],
    'eq negative comparison',
);

# TEST
is_deeply(
    [!($root ne 'not-root')],
    [''],
    'eq negative comparison',
);

{
    my $doc = XML::LibXML->load_xml( string => <<'EOT' )->documentElement;
<foo>
    <bar />
    <baz />
</foo>
EOT

    my ($bar_elem) = $doc->findnodes('//bar');
    my ($baz_elem) = $doc->findnodes('//baz');

    # TEST
    is_deeply([$bar_elem == $baz_elem], [''],
        '== comparison between two differenet nodes'
    );

    # TEST
    is_deeply([$bar_elem eq $baz_elem], [''],
        'eq comparison between two differenet nodes'
    );
}
__DATA__
<root attr1="foo" xmlns:x="http://localhost/" x:attr2="bar" />

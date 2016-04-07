use strict;
use warnings;
use Test::More;
use Scalar::Util;
use XML::LibXML;

if (defined (&Scalar::Util::weaken))
{
    plan tests => 1;
}
else
{
    plan skip_all => 'Need Scalar::Util::weaken';
}

my $is_destroyed;
BEGIN
{
    no warnings 'once', 'redefine';
    my $old = \&XML::LibXML::Element::DESTROY;
    *XML::LibXML::Element::DESTROY = sub
    {
        $is_destroyed++;
        $old->(@_);
    };
}

# Create element...
my $root = XML::LibXML->load_xml( IO => \*DATA )->documentElement;

# allow %hash to go out of scope quickly.
{
    my %hash = %$root;
    # assignment to ensure block is not optimized away
    $hash{foo} = 'phooey';
}

# Destroy element...
undef($root);

# Touch the fieldhash...
my %other = %{ XML::LibXML->load_xml( string => '<foo/>' )->documentElement };

# TEST
ok($is_destroyed, "does not leak memory");

__DATA__
<root attr1="foo" xmlns:x="http://localhost/" x:attr2="bar" />

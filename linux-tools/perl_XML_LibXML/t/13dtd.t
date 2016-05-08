
use strict;
use warnings;

use Test::More tests => 18;

use lib './t/lib';
use TestHelpers;

use XML::LibXML;

# TEST
ok(1, "Loaded");

my $dtdstr = slurp('example/test.dtd');

$dtdstr =~ s/\r//g;
$dtdstr =~ s/[\r\n]*$//;

# TEST
ok($dtdstr, "DTD String read");

{
    # parse a DTD from a SYSTEM ID
    my $dtd = XML::LibXML::Dtd->new('ignore', 'example/test.dtd');
    # TEST
    ok ($dtd, 'XML::LibXML::Dtd successful.');
    my $newstr = $dtd->toString();
    $newstr =~ s/\r//g;
    $newstr =~ s/^.*?\n//;
    $newstr =~ s/\n^.*\Z//m;
    # TEST
    is ($newstr, $dtdstr, 'DTD String same as new string.');
}

{
    # parse a DTD from a string
    my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
    # TEST
    ok ($dtd, '->parse_string');
}

{
    # validate with the DTD
    my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
    # TEST
    ok ($dtd, '->parse_string 2');
    my $xml = XML::LibXML->new->parse_file('example/article.xml');
    # TEST
    ok ($xml, 'parse the article.xml file');
    # TEST
    ok ($xml->is_valid($dtd), 'valid XML file');
    eval { $xml->validate($dtd) };
    # TEST
    ok ( !$@, 'Validates');
}

{
    # validate a bad document
    my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
    # TEST
    ok ($dtd, '->parse_string 3');
    my $xml = XML::LibXML->new->parse_file('example/article_bad.xml');
    # TEST
    ok(!$xml->is_valid($dtd), 'invalid XML');
    eval {
        $xml->validate($dtd);
    };
    # TEST
    ok ($@, '->validate throws an exception');

    my $parser = XML::LibXML->new();
    # TEST
    ok ($parser->validation(1), '->validation returns 1');
    # this one is OK as it's well formed (no DTD)

    eval{
        $parser->parse_file('example/article_bad.xml');
    };
    # TEST
    ok ($@, 'Threw an exception');
    eval {
        $parser->parse_file('example/article_internal_bad.xml');
    };
    # TEST
    ok ($@, 'Throw an exception 2');
}

# this test fails under XML-LibXML-1.00 with a segfault because the
# underlying DTD element in the C libxml library was freed twice

{
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file('example/dtd.xml');
    my @a = $doc->getChildnodes;
    # TEST
    is (scalar(@a), 2, "Two child nodes");
}

##
# Tests for ticket 2021
{
    my $dtd = XML::LibXML::Dtd->new("","");
    # TEST
    ok (!defined($dtd), "XML::LibXML::Dtd not defined." );
}

{
    my $dtd = XML::LibXML::Dtd->new('', 'example/test.dtd');
    # TEST
    ok ($dtd, "XML::LibXML::Dtd->new working correctly");
}

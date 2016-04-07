use strict;
use warnings;

use XML::LibXML;
# Should be 11.
use Test::More tests => 11;

# this test fails under XML-LibXML-1.00 with a segfault after the
# second parsing.  it was fixed by putting in code in getChildNodes
# to handle the special case where the node was the document node

  my $input = <<EOD;
<doc>
   <clean>   </clean>
   <dirty>   A   B   </dirty>
   <mixed>
      A
      <clean>   </clean>
      B
      <dirty>   A   B   </dirty>
      C
   </mixed>
</doc>
EOD

for my $time (0 .. 2) {
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_string($input);
    my @a = $doc->getChildnodes;
    # TEST*3
    is(scalar(@a), 1, "1 Child node - time $time");
}

my $parser = XML::LibXML->new();
my $doc = $parser->parse_string($input);
for my $time (0 .. 2) {
    my $e = $doc->getFirstChild;
    # TEST*3
    isa_ok ($e, 'XML::LibXML::Element',
        "first child is an Element - time No. $time"
    );
}

for my $time (0 .. 2) {
    my $e = $doc->getLastChild;
    # TEST*3
    isa_ok($e,'XML::LibXML::Element',
        "last child is an element - time No. $time"
    );
}

##
# Test Ticket 7645
{
    my $in = pack('U', 0x00e4);
    my $doc = XML::LibXML::Document->new();

    my $node = XML::LibXML::Element->new('test');
    $node->setAttribute(contents => $in);
    $doc->setDocumentElement($node);

    # TEST
    is( $node->serialize(), '<test contents="&#xE4;"/>', 'Node serialise works.' );

    $doc->setEncoding('utf-8');
    # Second output
    # TEST
    is( $node->serialize(),
        encodeToUTF8( 'iso-8859-1', '<test contents="ä"/>' ),
        'UTF-8 node serialize',
    );
}

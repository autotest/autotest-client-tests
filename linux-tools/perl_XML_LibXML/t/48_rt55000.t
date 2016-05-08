
use strict;
use warnings;

=head1 DESCRIPTION

If an element contains both a default namespace declaration and a second
namespace declaration, adding an attribute using the default namespace
declaration will cause that attribute to have the other prefix.

OS Version: FreeBSD 6.3-RELEASE
Perl Version: v5.8.8
LibXML Version: 1.70

See L<https://rt.cpan.org/Ticket/Display.html?id=55000> .

=cut

use Test::More tests => 6;

use XML::LibXML;

my $xml_string = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<element xmlns="uri"
xmlns:wrong="other">
</element>
XML

my $parser = XML::LibXML->new;
my $doc = $parser->parse_string($xml_string);
my $root = $doc->documentElement();
$root->setAttributeNS("uri", "prefix:attribute", "text");
$root->setAttributeNS("uri", "second", "text");

my $string = $doc->toString(1);

# TEST
unlike ($string, qr/[^\w:]attribute="text"/,
    "Not placed as an unprefixed attribute");
# TEST
unlike ($string, qr/\bwrong:attribute="text"/,
    "Not placed in the wrong namespace");

# TEST
like ($string, qr/\bprefix:attribute="text"/,
    "Placed in the right namespace");

# TEST
unlike ($string, qr/[^\w:]second="text"/,
    "Not placed as an unprefixed attribute");

# TEST
unlike ($string, qr/\bwrong:second="text"/,
    "Not placed in the wrong namespace");

# TEST
like ($string, qr/\bprefix:second="text"/,
    "Placed in the right namespace");


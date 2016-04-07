use strict;
use warnings;

use Test::More tests => 3;

use XML::LibXML;

# TEST
ok(1, 'Loaded fine');

my $p = XML::LibXML->new();
# TEST
ok ($p, 'Can initialize a new XML::LibXML instance');

my ($runtime_version) = (XML::LibXML::LIBXML_RUNTIME_VERSION() =~ /\A(\d+)/);

# TEST
if (!is (
    XML::LibXML::LIBXML_VERSION, $runtime_version,
    'LIBXML__VERSION == LIBXML_RUNTIME_VERSION',
))
{
   diag("DO NOT REPORT THIS FAILURE: Your setup of library paths is incorrect!");
}

diag( "\n\nCompiled against libxml2 version: ",XML::LibXML::LIBXML_VERSION,
     "\nRunning libxml2 version:          ",$runtime_version,
     "\n\n");

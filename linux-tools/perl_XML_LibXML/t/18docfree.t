use strict;
use warnings;

use Test::More tests => 1;
use XML::LibXML;

{
  my $doc = XML::LibXML::Document->new();
  $doc = XML::LibXML::Document->new();
}
# used to get "Attempt to free unreferenced scalar" here
ok(1, 'docfree Out of scope is OK - no "Attempt to free unreferenced scalar"');


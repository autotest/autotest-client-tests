use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

sub check( $$ );

check "OO-style use of XML::Dumper", <<XML;
<perldata>
 <arrayref memory_address="0x8296934">
  <item key="0" defined="false"></item>
  <item key="1"></item>
  <item key="2">Foo</item>
  <item key="3">
   <hashref memory_address="0x829c810">
    <item key="a" defined="false"></item>
    <item key="b"></item>
    <item key="c">Bar</item>
   </hashref>
  </item>
 </arrayref>
</perldata>
XML

# ============================================================
sub check( $$ ) {
# ============================================================
	my $test = shift;
	my $xml = shift;
	my $dump = new XML::Dumper;

	my $perl = $dump->xml2pl( $xml );
	my $roundtrip_xml = $dump->pl2xml( $perl );

	if( xml_compare( $xml, $roundtrip_xml )) {
		ok( 1 );
		return;
	}

	print STDERR
		"\nTest for $test failed: data doesn't match!\n\n" . 
		"Got:\n----\n'$xml'\n----\n".
		"Came up with:\n----\n'$roundtrip_xml'\n----\n";

	ok( 0 );
}


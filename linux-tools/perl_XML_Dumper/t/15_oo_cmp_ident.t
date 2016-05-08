use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 5 }

sub check( $$ );

check "a simple scalar", <<XML;
<perldata>
 <scalar>foo</scalar>
</perldata>
XML

check "a scalar reference", <<XML;
<perldata>
 <scalarref>Hi Mom</scalarref>
</perldata>
XML

check "a hash reference", <<XML;
<perldata>
 <hashref>
  <item key="key1">value1</item>
  <item key="key2">value2</item>
 </hashref>
</perldata>
XML

check "an array reference", <<XML;
<perldata>
 <arrayref>
  <item key="0">foo</item>
  <item key="1">bar</item>
 </arrayref>
</perldata>
XML

check "a combination of datatypes", <<XML;
<perldata>
 <arrayref>
  <item key="0">Scalar</item>
  <item key="1">
   <scalarref>ScalarRef</scalarref>
  </item>
  <item key="2">
   <arrayref>
    <item key="0">foo</item>
    <item key="1">bar</item>
   </arrayref>
  </item>
  <item key="3">
   <hashref>
    <item key="key1">value1</item>
    <item key="key2">value2</item>
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

	my $dump = new XML::Dumper();

	my $perl = $dump->xml2pl( $xml );
	my $roundtrip_xml = $dump->pl2xml( $perl );

	if( $dump->xml_compare( $xml, $roundtrip_xml ) && $dump->xml_identity( $xml, $xml )) {
		ok( 1 );
		return;
	}

	print STDERR
		"\nTest for $test failed: data doesn't match!\n\n" . 
		"Got:\n----\n'$xml'\n----\n".
		"Came up with:\n----\n'$roundtrip_xml'\n----\n";

	ok( 0 );
}


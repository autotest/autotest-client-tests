use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 3 }

sub check( $$ );

check "correct handling of undef()", <<XML;
<perldata>
 <hashref memory_address="0x8296934">
  <item key="a" defined="false"></item>
  <item key="b"></item>
  <item key="c">Foo</item>
  <item key="d">
   <hashref memory_address="0x829c810">
    <item key="d1" defined="false"></item>
    <item key="d2"></item>
    <item key="d3">Bar</item>
   </hashref>
  </item>
 </hashref>
</perldata>
XML

check "undef() for arrays", <<XML;
<perldata>
 <arrayref memory_address="0x8296934">
  <item key="0" defined="false"></item>
  <item key="1"></item>
  <item key="2">Foo</item>
  <item key="3">
   <arrayref memory_address="0x829c810">
    <item key="0" defined="false"></item>
    <item key="1"></item>
    <item key="2">Bar</item>
   </arrayref>
  </item>
 </arrayref>
</perldata>
XML

check "undef() for hashes", <<XML;
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
# Bug submitted 11/26/02 by Peter S. May
# ------------------------------------------------------------
	my $test = shift;
	my $xml = shift;

	my $perl = xml2pl( $xml );
	my $roundtrip_xml = pl2xml( $perl );

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


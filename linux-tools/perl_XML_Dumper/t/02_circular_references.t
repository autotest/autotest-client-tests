use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

sub check( $$ );

check "hash with a circular reference", <<XML;
<perldata>
 <hashref memory_address="0x40041d28">
  <item key="data">
   <hashref memory_address="0x40041d28">
   </hashref>
  </item>
  <item key="fname">Mike</item>
  <item key="lname">Wong</item>
 </hashref>
</perldata>
XML

# ============================================================
sub check( $$ ) {
# ============================================================
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


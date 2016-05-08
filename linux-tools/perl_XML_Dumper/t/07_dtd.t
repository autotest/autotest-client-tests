use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

sub check( $$ );

check "DTD", <<XML;
<?xml version="1.0"?>
<!DOCTYPE perldata [
	<!ELEMENT scalar (#PCDATA)>
	<!ELEMENT scalarref (#PCDATA)>
	<!ATTLIST scalarref 
		blessed_package CDATA #IMPLIED
		memory_address CDATA #IMPLIED>
	<!ELEMENT arrayref (item*)>
	<!ATTLIST arrayref 
		blessed_package CDATA #IMPLIED
		memory_address CDATA #IMPLIED>
	<!ELEMENT hashref (item*)>
	<!ATTLIST hashref 
		blessed_package CDATA #IMPLIED
		memory_address CDATA #IMPLIED>
	<!ELEMENT item (#PCDATA|scalar|scalarref|arrayref|hashref)*>
	<!ATTLIST item 
		key CDATA #REQUIRED
		defined CDATA #IMPLIED>
	<!ELEMENT perldata (scalar|scalarref|arrayref|hashref)*>
]>
<perldata>
 <scalar>foo</scalar>
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



package Scalar_object;
sub new { my ($class) = map { ref || $_ } shift; return bless \$_, $class; }

package Hash_object;
sub new { my ($class) = map { ref || $_ } shift; return bless {}, $class; }


package Array_object;
sub new { my ($class) = map { ref || $_ } shift; return bless [], $class; }

package main;
use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 3 }

sub check( $$ );

check "Scalar Object", <<XML;
<perldata>
 <scalarref blessed_package="Scalar_object">Hi Mom</scalarref>
</perldata>
XML

check "Hash Object", <<XML;
<perldata>
 <hashref blessed_package="Hash_object">
  <item key="key1">value1</item>
  <item key="key2">value2</item>
 </hashref>
</perldata>
XML

check "Array Object", <<XML;
<perldata>
 <arrayref blessed_package="Array_object">
  <item key="0">foo</item>
  <item key="1">bar</item>
 </arrayref>
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


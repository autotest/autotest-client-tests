use strict;
use warnings;

use Test;
use XML::Dumper;
use utf8;

BEGIN { plan tests => 4 }

sub check( $$ );

check "UTF8 xml", <<XML;
<perldata>
 <hashref>
  <item key="aa">ä</item>
  <item key="euro">€</item>
  <item key="iso_a">Ä</item>
  <item key="iso_oo">Ö</item>
  <item key="oo">ö</item>
 </hashref>
</perldata>
XML

check "UTF8 perl", {
	aa		=> 'ä',
	iso_a	=> 'Ä',
	oo		=> 'ö',
	iso_oo	=> 'Ö',
	euro	=> '€',
};

check "UTF8 write", {
	aa		=> 'ä',
	iso_a	=> 'Ä',
	oo		=> 'ö',
	iso_oo	=> 'Ö',
	euro	=> '€',
};

check "UTF8 read", {
	aa		=> 'ä',
	iso_a	=> 'Ä',
	oo		=> 'ö',
	iso_oo	=> 'Ö',
	euro	=> '€',
};

# ============================================================
sub check( $$ ) {
# ============================================================
	my $test = shift;
	my $data = shift;

	TEST: {
	local $_ = $test;
		if( /xml/ ) {
			my $xml = $data;
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
			last TEST;
		}

		if( /perl/ ) {
			my $perl = $data;
			my $xml = pl2xml( $perl );
			my $roundtrip_perl = xml2pl( $xml );

			my $ok = 1;
			foreach (sort keys %$perl) {
				$ok &= $perl->{ $_ } eq $roundtrip_perl->{ $_ };
			}
			if( $ok ) {
				ok( 1 );
				return;
			}
			print STDERR
				"\nTest for $test failed: data doesn't match!\n\n";
			last TEST;
		} 

		if( /write/ ) {
			my $perl = $data;
			pl2xml( $perl, 't/utf8_test.xml' );
			ok( 1 );
			return;
		}

		if( /read/ ) {
			my $perl = $data;
			my $roundtrip_perl = xml2pl( 't/utf8_test.xml' );
			my $ok = 1;
			foreach (sort keys %$perl) {
				$ok &= $perl->{ $_ } eq $roundtrip_perl->{ $_ };
			}
			if( $ok ) {
				ok( 1 );
				return;
			}
		}
	}

	ok( 0 );
}


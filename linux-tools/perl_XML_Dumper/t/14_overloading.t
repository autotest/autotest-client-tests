package main;
use strict;
use warnings;

use Test;
use XML::Dumper;
use lib qw( t/classes );

BEGIN { plan tests => 2 }

@INC = ("./t/data/", @INC);

sub check( $$ );

check "Scalar Object", <<XML;
<perldata>
 <scalarref blessed_package="Overloaded_object">Hi Mom</scalarref>
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

	} else {
		print STDERR
			"\nTest for $test failed: data doesn't match!\n\n" . 
			"Got:\n----\n'$xml'\n----\n".
			"Came up with:\n----\n'$roundtrip_xml'\n----\n";

		ok( 0 );
	}

	if( ${ $perl } eq "Hi Mom" ) {
		ok( 1 );

	} else {
		ok( 0 );
	}
}

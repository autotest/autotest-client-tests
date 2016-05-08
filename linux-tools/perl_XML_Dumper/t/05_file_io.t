use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

open FILETEST, "t/data/file.xml" or die "Can't open 't/data/file.xml' for reading $!";
my $xml = join '', <FILETEST>;
close FILETEST;

sub check( $$ );

check "File I/O", $xml;

# ============================================================
sub check( $$ ) {
# ============================================================
	my $test = shift;
	my $xml = shift;

	my $perl = xml2pl( 't/data/file.xml' );
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


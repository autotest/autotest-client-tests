use strict;
use warnings;

use Test::More;
use XML::Dumper;

BEGIN {
	eval { require Compress::Zlib; };
	if( $@ ) {
		plan skip_all => 'Compress::Zlib is not installed'
	} else {
		plan tests => 1;
	}
}

sub check( $ );

check "Gzip Compression";

# ============================================================
sub check( $ ) {
# ============================================================
# Richard Evans provided gzip header signature test code
# (twice, cuz I lost it the first time), 22 Jul 2003
# ------------------------------------------------------------
	my $test = shift;

	my $gz = Compress::Zlib::gzopen( 't/data/compression.xml.gz', 'rb' );
	my @xml;
	my $buffer;
	while( $gz->gzread( $buffer ) > 0 ) {
		push @xml, $buffer;
	}
	$gz->gzclose();
	my $xml = join '', @xml;
	my $perl = xml2pl( 't/data/compression.xml.gz' );
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


use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

sub check( $$ );

check "0.72 removes control characters", <<XML
<perldata>
 <hashref memory_address="0x8103854">
  <item key="a"></item>
 </hashref>
</perldata>
XML

;

# ============================================================
sub check( $$ ) {
# ============================================================
	my $test = shift;
	my $new_xml = shift;

	my $old = { a => "" };

	my $roundtrip_xml = pl2xml( $old );

	if( xml_compare( $new_xml, $roundtrip_xml )) {
		ok( 1 );
		return;
	}

	print STDERR
		"\nTest for $test failed: Control characters not filtered!\n\n" . 

	ok( 0 );
}

__END__



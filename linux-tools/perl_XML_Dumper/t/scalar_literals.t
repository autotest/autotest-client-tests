use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 1 }

sub check( $$ );

check "correct handling of scalar literals", 
\"020525264";

# ============================================================
sub check( $$ ) {
# ============================================================
# Bug submitted 11/20/02 by Niels Vetger
# ------------------------------------------------------------
	my $test = shift;
	my $perl = shift;


	if( eval { pl2xml( $perl ) } && not $@ ) {
		ok( 1 );
	} else {
		ok( 0 );
	}
}


#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'constant' );
}

diag( "Testing constant $constant::VERSION, Perl $], $^X" );

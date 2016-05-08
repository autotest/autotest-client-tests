package main;
use strict;
use warnings;

use Test;
use XML::Dumper;
use lib qw( t/classes );

BEGIN { plan tests => 3 }

@INC = ("./t/data/", @INC);

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

        my $perl;
        
        # Choke warnins
        {
            local $SIG{__WARN__} = sub { 1; };
	    $perl = xml2pl( $xml );
        }
        ok($perl->can('new'));
}

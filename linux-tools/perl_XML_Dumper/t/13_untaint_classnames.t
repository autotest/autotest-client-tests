package main;
use strict;
use warnings;

use Test;
use XML::Dumper;
use lib qw( t/classes );

BEGIN { plan tests => 16 }

@INC = ("./t/data/", @INC);

sub check( $$ );

check "Scalar Object", <<XML;
<perldata>
 <scalarref blessed_package="Scalar_object; delete(\$ENV{THE_ANSWER});">Hi Mom</scalarref>
</perldata>
XML


check "Hash Object", <<XML;
<perldata>
 <hashref blessed_package="Hash_object; delete(\$ENV{THE_ANSWER});">
  <item key="key1">value1</item>
  <item key="key2">value2</item>
 </hashref>
</perldata>
XML

check "Array Object", <<XML;
<perldata>
 <arrayref blessed_package="Array_object; delete(\$ENV{THE_ANSWER});">
  <item key="0">foo</item>
  <item key="1">bar</item>
 </arrayref>
</perldata>
XML

check "Long Namespace", <<XML;
<perldata>
 <scalarref blessed_package="Class::With::A::Long::Namespace::Scalar_object; delete(\$ENV{THE_ANSWER});">Hi Mom</scalarref>
</perldata>
XML

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

check "Long Namespace", <<XML;
<perldata>
 <scalarref blessed_package="Class::With::A::Long::Namespace::Scalar_object">Hi Mom</scalarref>
</perldata>
XML

# ============================================================
sub check( $$ ) {
# ============================================================
	my $test = shift;
	my $xml = shift;

        my $perl = undef;

        $ENV{THE_ANSWER} = 42;

        # Choke warnings
        eval {
            local $SIG{__WARN__} = sub { 1; };
            $perl = xml2pl( $xml );
        };

        # ===== HANDLE MALICIOUS CODE
        if( $@ =~ /delete/ ) {
			# Verify that parsing/undumping failed...
			ok(!defined($perl));

			# ...that it die()'d...
			ok($@);

			# ...and that it didn't run the malicious code...
			ok(exists($ENV{THE_ANSWER}) and 42 == $ENV{THE_ANSWER}); 

        # ===== HANDLE ACCEPTABLE CODE
        } else {
            ok( defined( $perl ));
        }
}

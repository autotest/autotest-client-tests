use strict;
use warnings;

# Should be 12.
use Test::More tests => 12;

use XML::LibXML::Common qw( :libxml :encoding );

use constant TEST_STRING_GER => "Hänsel und Gretel";
use constant TEST_STRING_GER2 => "täst";
use constant TEST_STRING_UTF => 'test';
use constant TEST_STRING_JP  => 'À¸ÇþÀ¸ÊÆÀ¸Íñ';

# TEST
ok(1, 'Loading');

#########################

# TEST
is (XML_ELEMENT_NODE, 1, 'XML_ELEMENT_NODE is 1.' );

# encoding();

# TEST
is (decodeFromUTF8(
        'iso-8859-1', encodeToUTF8('iso-8859-1', TEST_STRING_GER2 )
    ),
    TEST_STRING_GER2,
    'Roundup trip from UTF-8 to ISO-8859-1 and back.',
);

# TEST
is ( decodeFromUTF8(
        'UTF-8' , encodeToUTF8('UTF-8', TEST_STRING_UTF )
    ),
    TEST_STRING_UTF,
    'Rountrip trip through UTF-8',
);


my $u16 =
    decodeFromUTF8( 'UTF-16', encodeToUTF8('UTF-8', TEST_STRING_UTF ) )
    ;

# TEST
is ( length($u16), 2*length(TEST_STRING_UTF),
    'UTF-16 String is twice as long.'
);

my $u16be = decodeFromUTF8( 'UTF-16BE',
                            encodeToUTF8('UTF-8', TEST_STRING_UTF ) );
# TEST
is ( length($u16be), 2*length(TEST_STRING_UTF),
    'UTF-16BE String is twice as long.'
);

my $u16le = decodeFromUTF8( 'UTF-16LE',
                            encodeToUTF8('UTF-8', TEST_STRING_UTF ) );
# TEST
is ( length($u16le), 2*length(TEST_STRING_UTF),
    'UTF-16LE String is twice as long.'
);

# Bad encoding name tests.
eval {
    my $str = encodeToUTF8( "foo" , TEST_STRING_GER2 );
};
# TEST
ok( $@, 'Exception was thrown.' );

# TEST
is (encodeToUTF8( 'UTF-16' , '' ), '', 'Encoding empty string to UTF-8');

# TEST
ok (!defined(encodeToUTF8( 'UTF-16' , undef )),
    'encoding undef to UTF-8 is undefined'
);

# TEST
is (decodeFromUTF8( 'UTF-16' , '' ), '', 'decodeFromUTF8 of empty string');

# TEST
ok (!defined(decodeFromUTF8( 'UTF-16' , undef )), 'decodeFromUTF8 of undef.');

# here should be a test to test badly encoded strings. but for some
# reasons i am unable to create an appropriate test :(

# uncomment these lines if your system is capable to handel not only i
# so latin 1
#ok( decodeFromUTF8('EUC-JP',
#                   encodeToUTF8('EUC-JP',
#                                TEST_STRING_JP ) ),
#    TEST_STRING_JP );

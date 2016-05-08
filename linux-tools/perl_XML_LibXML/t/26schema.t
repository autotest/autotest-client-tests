# $Id$

##
# Testcases for the XML Schema interface
#

use strict;
use warnings;

use lib './t/lib';
use TestHelpers;

use Test::More;

use XML::LibXML;

if ( XML::LibXML::LIBXML_VERSION >= 20510 ) {
    plan tests => 6;
}
else {
    plan skip_all => 'No Schema Support compiled.';
}

my $xmlparser = XML::LibXML->new();

my $file         = "test/schema/schema.xsd";
my $badfile      = "test/schema/badschema.xsd";
my $validfile    = "test/schema/demo.xml";
my $invalidfile  = "test/schema/invaliddemo.xml";


# 1 parse schema from a file
{
    my $rngschema = XML::LibXML::Schema->new( location => $file );
    # TEST
    ok ( $rngschema, 'Good XML::LibXML::Schema was initialised' );

    eval { $rngschema = XML::LibXML::Schema->new( location => $badfile ); };
    # TEST
    ok( $@, 'Bad XML::LibXML::Schema throws an exception.' );
}

# 2 parse schema from a string
{
    my $string = slurp($file);

    my $rngschema = XML::LibXML::Schema->new( string => $string );
    # TEST
    ok ( $rngschema, 'RNG Schema initialized from string.' );

    $string = slurp($badfile);
    eval { $rngschema = XML::LibXML::Schema->new( string => $string ); };
    # TEST
    ok( $@, 'Bad string schema throws an excpetion.' );
}

# 3 validate a document
{
    my $doc       = $xmlparser->parse_file( $validfile );
    my $rngschema = XML::LibXML::Schema->new( location => $file );

    my $valid = 0;
    eval { $valid = $rngschema->validate( $doc ); };
    # TEST
    is( $valid, 0, 'validate() returns 0 to indicate validity of valid file.' );

    $doc       = $xmlparser->parse_file( $invalidfile );
    $valid     = 0;
    eval { $valid = $rngschema->validate( $doc ); };
    # TEST
    ok ( $@, 'Invalid file throws an excpetion.');
}


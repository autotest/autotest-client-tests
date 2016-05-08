##
# $Id$
#
# This should test the XML::LibXML internal encoding/ decoding.
# Since most of the internal encoding code is dependent on
# the perl version the module is built for. only the encodeToUTF8() and
# decodeFromUTF8() functions are supposed to be general, while all the
# magic code is only available for more recent perl version (5.6+)
#
# Added note by Shlomi Fish: we are now perl-5.8.x and above so I removed
# the 5.6.x+ test.

use strict;
use warnings;

use Test::More;

{
    my $tests        = 1;
    my $basics       = 0;
    my $magic        = 6;
    my $step = $basics + $magic;

    $tests += $step;

    if ( defined $ENV{TEST_LANGUAGES} ) {
      if ( $ENV{TEST_LANGUAGES} eq "all" ) {
          $tests += 2 * $step;
      } elsif ( $ENV{TEST_LANGUAGES} eq "EUC-JP"
		or $ENV{TEST_LANGUAGES} eq "KOI8-R" ) {
        $tests += $step;
      }
    }
    plan tests => $tests;
}

use XML::LibXML::Common;
use XML::LibXML;

# TEST
ok(1, 'Loading');

my $p = XML::LibXML->new();

# encoding tests
# ok there is the UTF16 test still missing

my $tstr_utf8       = 'test';
my $tstr_iso_latin1 = "täst";

my $domstrlat1 = q{<?xml version="1.0" encoding="iso-8859-1"?>
<täst>täst</täst>
};

{
    # magic encoding tests

    my $dom_latin1 = XML::LibXML::Document->new('1.0', 'iso-8859-1');
    my $elemlat1   = $dom_latin1->createElement( $tstr_iso_latin1 );

    $dom_latin1->setDocumentElement( $elemlat1 );

    # TEST
    is( decodeFromUTF8( 'iso-8859-1' ,$elemlat1->toString()),
        "<$tstr_iso_latin1/>", ' TODO : Add test name');
    # TEST
    is( $elemlat1->toString(0,1), "<$tstr_iso_latin1/>", ' TODO : Add test name');

    my $elemlat2   = $dom_latin1->createElement( "Öl" );
    # TEST
    is( $elemlat2->toString(0,1), "<Öl/>", ' TODO : Add test name');

    $elemlat1->appendText( $tstr_iso_latin1 );

    # TEST
    is( decodeFromUTF8( 'iso-8859-1' ,$elemlat1->string_value()),
        $tstr_iso_latin1, ' TODO : Add test name');
    # TEST
    is( $elemlat1->string_value(1), $tstr_iso_latin1, ' TODO : Add test name');

    # TEST
    is( $dom_latin1->toString(), $domstrlat1, ' TODO : Add test name' );

}

exit(0) unless defined $ENV{TEST_LANGUAGES};

if ( $ENV{TEST_LANGUAGES} eq 'all' or $ENV{TEST_LANGUAGES} eq "EUC-JP" ) {
    # japanese encoding (EUC-JP)

    my $tstr_euc_jp     = 'À¸ÇþÀ¸ÊÆÀ¸Íñ';
    my $domstrjp = q{<?xml version="1.0" encoding="EUC-JP"?>
<À¸ÇþÀ¸ÊÆÀ¸Íñ>À¸ÇþÀ¸ÊÆÀ¸Íñ</À¸ÇþÀ¸ÊÆÀ¸Íñ>
};


    {
        my $dom_euc_jp = XML::LibXML::Document->new('1.0', 'EUC-JP');
        my $elemjp = $dom_euc_jp->createElement( $tstr_euc_jp );


        # TEST

        is( decodeFromUTF8( 'EUC-JP' , $elemjp->nodeName()),
            $tstr_euc_jp, ' TODO : Add test name' );
        # TEST
        is( decodeFromUTF8( 'EUC-JP' ,$elemjp->toString()),
            "<$tstr_euc_jp/>", ' TODO : Add test name');
        # TEST
        is( $elemjp->toString(0,1), "<$tstr_euc_jp/>", ' TODO : Add test name');

        $dom_euc_jp->setDocumentElement( $elemjp );
        $elemjp->appendText( $tstr_euc_jp );

        # TEST

        is( decodeFromUTF8( 'EUC-JP' ,$elemjp->string_value()),
            $tstr_euc_jp, ' TODO : Add test name');
        # TEST
        is( $elemjp->string_value(1), $tstr_euc_jp, ' TODO : Add test name');

        # TEST

        is( $dom_euc_jp->toString(), $domstrjp, ' TODO : Add test name' );
    }

}

if ( $ENV{TEST_LANGUAGES} eq 'all' or $ENV{TEST_LANGUAGES} eq "KOI8-R" ) {
    # cyrillic encoding (KOI8-R)

    my $tstr_koi8r       = 'ÐÒÏÂÁ';
    my $domstrkoi = q{<?xml version="1.0" encoding="KOI8-R"?>
<ÐÒÏÂÁ>ÐÒÏÂÁ</ÐÒÏÂÁ>
};


    {
        my ($dom_koi8, $elemkoi8);

        $dom_koi8 = XML::LibXML::Document->new('1.0', 'KOI8-R');
        $elemkoi8 = $dom_koi8->createElement( $tstr_koi8r );

        # TEST

        is( decodeFromUTF8( 'KOI8-R' ,$elemkoi8->nodeName()),
            $tstr_koi8r, ' TODO : Add test name' );

        # TEST

        is( decodeFromUTF8( 'KOI8-R' ,$elemkoi8->toString()),
            "<$tstr_koi8r/>", ' TODO : Add test name');
        # TEST
        is( $elemkoi8->toString(0,1), "<$tstr_koi8r/>", ' TODO : Add test name');

        $elemkoi8->appendText( $tstr_koi8r );

        # TEST

        is( decodeFromUTF8( 'KOI8-R' ,$elemkoi8->string_value()),
            $tstr_koi8r, ' TODO : Add test name');
        # TEST
        is( $elemkoi8->string_value(1),
            $tstr_koi8r, ' TODO : Add test name');
        $dom_koi8->setDocumentElement( $elemkoi8 );

        # TEST

        is( $dom_koi8->toString(),
            $domstrkoi, ' TODO : Add test name' );

    }
}

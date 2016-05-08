#!/usr/bin/perl

use strict;
use warnings;

# Bug #66642 for XML-LibXML: $err->column() incorrectly maxed out as 80
# https://rt.cpan.org/Public/Bug/Display.html?id=66642 .

use Test::More tests => 1;

use XML::LibXML qw();

eval {
    XML::LibXML->new()->parse_string(
'<foo attr1="value1" attr2="value2" attr3="value2" attr4="value2"'
. ' attr5="value2" attr6="value2" attr7="value2" attr8="value2"'
. ' attr9="value2" attr10="value2" attr11="value2" attr12="value2"'
. ' attr13="value2"attr14="value2" attr15="value2" />'
    )
};

SKIP:
{
    my $err = $@;
    # This is a fix for:
    # https://rt.cpan.org/Ticket/Display.html?id=69070
    # << t/46err_column.t is broken on centos/RHEL 4 >>

    # On this system, libxml is as follows:
    # libxml2-devel-2.6.16-12.8

    if (! ref($err))
    {
        skip('parse_string returned a string - not an XML::LibXML::Error object - probably an old libxml2',
            1
        );
    }
    # TEST
    is ($err->column(), 203, "Column is OK.");
}

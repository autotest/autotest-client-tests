#!/usr/bin/perl

# Fix the handling of XML::LibXML::InputCallbacks at load_xml().
# - https://rt.cpan.org/Ticket/Display.html?id=58190
# - The problem was that the input callbacks were not cloned in
# _clone().

use strict;
use warnings;

use Test::More tests => 3;

use XML::LibXML;

{
    my $got_open = 0;
    my $got_read = 0;
    my $got_close = 0;

    my $input_callbacks = XML::LibXML::InputCallback->new();
    $input_callbacks->register_callbacks([
            sub { 1 },
            sub { $got_open = 1; open my $fh, '<', shift; return $fh; },
            sub { $got_read = 1; my $buffer; read(shift, $buffer, shift); return $buffer; },
            sub { $got_close = 1; close shift },
        ]);

    my $xml_parser = XML::LibXML->new();
    $xml_parser->input_callbacks($input_callbacks);

    my $TEST_FILENAME = 'example/dromeds.xml';

    $xml_parser->load_xml(location => $TEST_FILENAME);

    # TEST
    ok ($got_open, 'load_xml() encountered the open InputCallback');

    # TEST
    ok ($got_read, 'load_xml() encountered the read InputCallback');

    # TEST
    ok ($got_close, 'load_xml() encountered the close InputCallback');
}

# $Id: 29_struct_errors.t,v 1.1.2.2 2006/06/22 14:34:47 pajas Exp $
# First version of the new structured error test suite

use strict;
use warnings;

use Test::More;
use XML::LibXML;

if (! XML::LibXML::HAVE_STRUCT_ERRORS() )
{
    plan skip_all => 'Does not have struct errors - skipping';
}
else
{
    plan tests => 7;
}

use XML::LibXML::Error;
use XML::LibXML::ErrNo;

{
    my $p = XML::LibXML->new();
    my $xmlstr = '<X></Y>';

    eval {
        my $doc = $p->parse_string( $xmlstr );
    };
    my $err = $@;
    # TEST
    ok (defined($err), 'Error is defined.');
    # TEST
    isa_ok ($err, "XML::LibXML::Error", '$err is an XML::LibXML::Error');
    # TEST
    is ($err->domain(), "parser", 'domain');
    # TEST
    is ($err->line(), 1, 'line');
    # TEST
    ok ($err->code == XML::LibXML::ErrNo::ERR_TAG_NAME_MISMATCH, ' TODO : Add test name');

    my $fake_err = XML::LibXML::Error->new('fake error');
    my $domain_num = @XML::LibXML::Error::error_domains;      # too big
    $fake_err->{domain} = $domain_num;                        # white-box test
    # TEST
    is($fake_err->domain, "domain_$domain_num",
        '$err->domain is reasonable on unknown domain');
    {
        my $warnings = 0;
        local $SIG{__WARN__} = sub { $warnings++; warn "@_\n" };
        my $s = $fake_err->as_string;
        # TEST
        is($warnings, 0,
            'No warnings when stringifying unknown-domain error',
        );
    }
}

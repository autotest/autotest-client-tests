#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use lib './t/lib';
use TestHelpers;

use Test::More tests => 3;

use XML::LibXML;

# This is a check for:
# https://rt.cpan.org/Ticket/Display.html?id=53270

{
    my $content = utf8_slurp('example/yahoo-finance-html-with-errors.html');

    my $parser = XML::LibXML->new;

    $parser->set_option('recover', 1);
    $parser->set_option('suppress_errors', 1);

    my @warnings;

    local $SIG{__WARN__} = sub {
        my $warning = shift;
        push @warnings, $warning;
    };
    my $dom = $parser->load_html(string => $content);

    # TEST
    eq_or_diff(
        \@warnings,
        [],
        'suppress_errors worked.',
    );
}

{
    # These are tests for https://rt.cpan.org/Ticket/Display.html?id=58024 :
    # <<<
    # In XML::LibXML, warnings are not suppressed when specifying the recover
    # or recover_silently flags as per the following excerpt from the manpage:
    # >>>

    my $txt = <<'EOS';
<div>
<a href="milu?a=eins&b=zwei"> ampersand not URL-encoded </a>
<!-- HTML parser error : htmlParseEntityRef: expecting ';' -->
</div>
EOS

    {
        my $buf = '';
        open my $fh, '>', \$buf;
        # redirect STDERR there
        local *STDERR = $fh;

        XML::LibXML->new(recover => 1)->load_html( string => $txt );
        close($fh);

        # TEST
        like ($buf, qr/htmlParseEntityRef:/, 'warning emitted');
    }
    {
        my $buf = '';
        open my $fh, '>', \$buf;
        local *STDERR = $fh;
        XML::LibXML->new(recover => 2)->load_html( string => $txt );
        close($fh);
        # TEST
        is ($buf, '', 'No warning emitted.');
    }
}

=head1 COPYRIGHT & LICENSE

Copyright 2011 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

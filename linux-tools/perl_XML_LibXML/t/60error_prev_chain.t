# This test script checks for:
#
# https://rt.cpan.org/Ticket/Display.html?id=56671 .
#
# It makes sure an error chain cannot be too long, because if it is it consumes
# a lot of RAM.

use strict;
use warnings;

no warnings 'recursion';

use Test::More;

use XML::LibXML;

{
    my $parser = XML::LibXML->new();
    $parser->validation(0);
    $parser->load_ext_dtd(0);

    eval
    {
        local $^W = 0;
        $parser->parse_file('example/JBR-ALLENtrees.htm');
    };

    my $err = $@;
    my $count = 0;

    if( $err && !ref($err) ) {
      plan skip_all => 'The local libxml library does not support errors as objects to $@';
    }
    plan tests => 1;

    while (defined($err) && $count < 200)
    {
        $err = $err->_prev();
    }
    continue
    {
        $count++;
    }

    # TEST
    ok ((!$err), "Reached the end of the chain.");
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

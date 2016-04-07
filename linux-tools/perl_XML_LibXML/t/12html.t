
use strict;
use warnings;

# should be 43.
use Test::More tests => 43;

use XML::LibXML;
use IO::File;

# TEST
ok(1, ' TODO : Add test name');

my $html = "example/test.html";

my $parser = XML::LibXML->new();
{
    my $doc = $parser->parse_html_file($html);
    # TEST
    ok($doc, ' TODO : Add test name');
}

my $fh;

open $fh, '<', $html
    or die "Can't open '$html': $!";

my $string;
{
    local $/;
    $string = <$fh>;
}

seek($fh, 0, 0);

# TEST

ok($string, ' TODO : Add test name');

my $doc = $parser->parse_html_string($string);

# TEST

ok($doc, ' TODO : Add test name');

undef $doc;

$doc = $parser->parse_html_fh($fh);

# TEST

ok($doc, ' TODO : Add test name');

$fh->close();

# parsing HTML's CGI calling links

my $strhref = <<EOHTML;

<html>
    <body>
        <a href="http:/foo.bar/foobar.pl?foo=bar&bar=foo">
            foo
        </a>
        <p>test
    </body>
</html>
EOHTML

my $htmldoc;

$parser->recover(1);
eval {
    local $SIG{'__WARN__'} = sub { };
    $htmldoc = $parser->parse_html_string( $strhref );
};

# ok( not $@ );
# TEST
ok( $htmldoc, ' TODO : Add test name' );

# parse_html_string with encoding
# encodings
SKIP:
{
    if (! eval { require Encode; })
    {
        skip("Encoding related tests require Encode", 14);
    }
    use utf8;

    my $utf_str = "ěščř";

    # w/o 'meta' charset
    $strhref = <<EOHTML;
<html>
  <body>
    <p>$utf_str</p>
  </body>
</html>
EOHTML

    # TEST

    ok( Encode::is_utf8($strhref), ' TODO : Add test name' );
    $htmldoc = $parser->parse_html_string( $strhref );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser->parse_html_string( $strhref,
        {
            encoding => 'UTF-8'
        }
    );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');


    my $iso_str = Encode::encode('iso-8859-2', $strhref);
    $htmldoc = $parser->parse_html_string( $iso_str,
        {
            encoding => 'iso-8859-2'
        }
    );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    # w/ 'meta' charset
    $strhref = <<EOHTML;
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;
      charset=iso-8859-2">
  </head>
  <body>
    <p>$utf_str</p>
  </body>
</html>
EOHTML

    $htmldoc = $parser->parse_html_string( $strhref, { encoding => 'UTF-8' });
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $iso_str = Encode::encode('iso-8859-2', $strhref);
    $htmldoc = $parser->parse_html_string( $iso_str );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser->parse_html_string( $iso_str, { encoding => 'iso-8859-2',
            URI => 'foo'
        } );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    # TEST
    is($htmldoc->URI, 'foo', ' TODO : Add test name');
}

# parse example/enc_latin2.html
# w/ 'meta' charset
{
    use utf8;
    my $utf_str = "ěščř";
    my $test_file = 'example/enc_latin2.html';
    my $fh;

    $htmldoc = $parser->parse_html_file( $test_file );
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser->parse_html_file( $test_file, { encoding => 'iso-8859-2',
            URI => 'foo'
        });
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    # TEST
    is($htmldoc->URI, 'foo', ' TODO : Add test name');

    open $fh, '<', $test_file
        or die "Cannot open '$test_file' for reading - $!";
    $htmldoc = $parser->parse_html_fh( $fh );
    close $fh;
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    open $fh, '<', $test_file
        or die "Cannot open '$test_file' for reading - $!";
    $htmldoc = $parser->parse_html_fh( $fh, { encoding => 'iso-8859-2',
            URI => 'foo',
        });
    close $fh;
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->URI, 'foo', ' TODO : Add test name');
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    SKIP:
    {
        my $num_tests = 2;
        if (1000*$] < 5008)
        {
            skip("skipping for Perl < 5.8", $num_tests);
        }
        elsif (20627 > XML::LibXML::LIBXML_VERSION)
        {
            skip("skipping for libxml2 < 2.6.27", $num_tests);
        }
        # translate to UTF8 on perl-side
        open $fh, '<:encoding(iso-8859-2)', $test_file
            or die "Cannot open '$test_file' for reading - $!";
        $htmldoc = $parser->parse_html_fh( $fh, { encoding => 'UTF-8' });
        close $fh;
        # TEST
        ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
        # TEST
        is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    }
}

# parse example/enc2_latin2.html
# w/o 'meta' charset
{
    use utf8;
    my $utf_str = "ěščř";
    my $test_file = 'example/enc2_latin2.html';
    my $fh;

    $htmldoc = $parser->parse_html_file( $test_file, { encoding => 'iso-8859-2' });
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    open $fh, '<', $test_file
        or die "Cannot open '$test_file' for reading - $!";
    $htmldoc = $parser->parse_html_fh( $fh, { encoding => 'iso-8859-2' });
    close $fh;
    # TEST
    ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    SKIP:
    {
        if (1000*$] < 5008)
        {
            skip("skipping for Perl < 5.8", 2);
        }
        # translate to UTF8 on perl-side
        open my $fh, '<:encoding(iso-8859-2)', $test_file
            or die "Cannot open '$test_file' for reading - $!";
        $htmldoc = $parser->parse_html_fh( $fh, { encoding => 'UTF-8' } );
        close $fh;
        # TEST
        ok( $htmldoc && $htmldoc->getDocumentElement, ' TODO : Add test name' );
        # TEST
        is($htmldoc->findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    }
}


{
  # 44715

  my $html = <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Test &amp; Test some more</title>
</head>
<body>
<p>Meet you at the caf&eacute;?</p>
<p>How about <a href="http://example.com?mode=cafe&id=1&ref=foo">this one</a>?
</p>
<input class="wibble" id="foo" value="working" />
</body>
</html>
EOF
  my $parser = XML::LibXML->new;
  eval {
    $doc = $parser->parse_html_string(
      $html => { recover => 1, suppress_errors => 1 }
     );
  };
  # TEST
  ok (!$@, 'No exception was thrown.');
  # TEST
  ok ($doc, ' Parsing was successful.');
  my $root = $doc && $doc->documentElement;
  my $val = $root && $root->findvalue('//input[@id="foo"]/@value');
  # TEST
  is ($val, 'working', 'XPath');
}


{
    # 70878
    # HTML_PARSE_NODEFDTD

    SKIP: {
        skip("LibXML version is below 20708", 2) unless ( XML::LibXML::LIBXML_VERSION >= 20708 );

        my $html = q(<body bgcolor='#ffffff' style="overflow: hidden;" leftmargin=0 MARGINWIDTH=0 CLASS="text">);
        my $p = XML::LibXML->new;

        # TEST
        like( $p->parse_html_string( $html, {
                    recover => 2,
                    no_defdtd => 1,
                    encoding => 'UTF-8' } )->toStringHTML, qr/^\Q<html>\E/, 'do not add a default DOCTYPE' );

        # TEST
        like ( $p->parse_html_string( $html, {
                    recover => 2,
                    encoding => 'UTF-8' } )->toStringHTML, qr/^\Q<!DOCTYPE html\E/, 'add a default DOCTYPE' );
    }
}


# $Id$

use strict;
use warnings;

use lib './t/lib';
use TestHelpers;
use Counter;
use Stacker;

# Should be 25.
use Test::More tests => 25;
use XML::LibXML;

sub _create_counter_pair
{
    my ($worker_cb, $predicate_cb) = @_;

    my $non_global_counter = Counter->new(
        {
            gen_cb => sub {
                my $inc_cb = shift;
                return sub {
                    return $worker_cb->(
                        sub {
                            if (!$predicate_cb->())
                            {
                                $inc_cb->()
                            }
                            return;
                        }
                    )->(@_);
                }
            },
        }
    );

    my $global_counter = Counter->new(
        {
            gen_cb => sub {
                my $inc_cb = shift;
                return sub {
                    return $worker_cb->(
                        sub {
                            if ($predicate_cb->())
                            {
                                $inc_cb->()
                            }
                            return;
                        }
                    )->(@_);
                }
            },
        }
    );

    return ($non_global_counter, $global_counter);
}

my ($open1_non_global_counter, $open1_global_counter) =
    _create_counter_pair(
        sub {
            my $cond_cb = shift;
            return sub {
                my $fn = shift;
                # warn("open: $f\n");

                if (open my $fh, '<', $fn)
                {
                    $cond_cb->();
                    return $fh;
                }
                else
                {
                    return 0;
                }
            };
        },
        sub { return defined($XML::LibXML::open_cb); },
    );

my $open2_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;
            return sub {
                my ($fn) = @_;
                # warn("open2: $_[0]\n");

                $fn =~ s/([^\d])(\.xml)$/${1}4$2/; # use a different file
                my ($ret, $verdict);
                if ($verdict = open (my $file, '<', $fn))
                {
                    $ret = $file;
                }
                else
                {
                    $ret = 0;
                }

                $inc_cb->();

                return $ret;
            };
        },
    }
);

my ($match1_non_global_counter, $match1_global_counter) =
    _create_counter_pair(
        sub {
            my $cond_cb = shift;
            return sub {
                $cond_cb->();

                return 1;
            };
        },
        sub { return defined($XML::LibXML::match_cb); },
    );

my ($close1_non_global_counter, $close1_global_counter) =
    _create_counter_pair(
        sub {
            my $cond_cb = shift;
            return sub {
                my ($fh) = @_;
                # warn("open: $f\n");

                $cond_cb->();

                if ($fh)
                {
                    $fh->close();
                }

                return 1;
            };
        },
        sub { return defined($XML::LibXML::close_cb); },
    );

my ($read1_non_global_counter, $read1_global_counter) =
    _create_counter_pair(
        sub {
            my $cond_cb = shift;
            return sub {
                my ($fh) = @_;
                # warn "read!";
                my $rv = undef;
                my $n = 0;
                if ( $fh ) {
                    $n = $fh->read( $rv , $_[1] );
                    if ($n > 0)
                    {
                        $cond_cb->();
                    }
                }
                return $rv;
            };
        },
        sub { return defined($XML::LibXML::read_cb); },
    );

{
    # first test checks if local callbacks work
    my $parser = XML::LibXML->new();
    # TEST
    ok($parser, 'Parser was initted.');

    $parser->match_callback( $match1_non_global_counter->cb() );
    $parser->read_callback( $read1_non_global_counter->cb() );
    $parser->open_callback( $open1_non_global_counter->cb() );
    $parser->close_callback( $close1_non_global_counter->cb() );

    $parser->expand_xinclude( 1 );

    my $dom = $parser->parse_file("example/test.xml");

    # TEST
    $read1_non_global_counter->test(2, 'read1 for expand_include called twice.');
    # TEST
    $close1_non_global_counter->test(2, 'close1 for expand_include called twice.');
    # TEST
    $match1_non_global_counter->test(2, 'match1 for expand_include called twice.');

    # TEST
    $open1_non_global_counter->test(2, 'expand_include open1 worked.');

    # TEST
    ok($dom, 'DOM was returned.');
    # warn $dom->toString();

    my $root = $dom->getDocumentElement();

    my @nodes = $root->findnodes( 'xml/xsl' );
    # TEST
    ok( scalar(@nodes), 'Found nodes.' );
}

{
    # test per parser callbacks. These tests must not fail!

    my $parser = XML::LibXML->new();
    my $parser2 = XML::LibXML->new();

    # TEST
    ok($parser, '$parser was init.');
    # TEST
    ok($parser2, '$parser2 was init.');

    $parser->match_callback( $match1_non_global_counter->cb() );
    $parser->read_callback( $read1_non_global_counter->cb() );
    $parser->open_callback( $open1_non_global_counter->cb() );
    $parser->close_callback( $close1_non_global_counter->cb() );

    $parser->expand_xinclude( 1 );

    $parser2->match_callback( \&match2 );
    $parser2->read_callback( \&read2 );
    $parser2->open_callback( $open2_counter->cb() );
    $parser2->close_callback( \&close2 );

    $parser2->expand_xinclude( 1 );

    my $dom1 = $parser->parse_file( "example/test.xml");
    my $dom2 = $parser2->parse_file("example/test.xml");

    # TEST
    $read1_non_global_counter->test(2, 'read1 for $parser out of ($parser,$parser2)');
    # TEST
    $close1_non_global_counter->test(2, 'close1 for $parser out of ($parser,$parser2)');

    # TEST
    $match1_non_global_counter->test(2, 'match1 for $parser out of ($parser,$parser2)');
    # TEST
    $open1_non_global_counter->test(2, 'expand_include for $parser out of ($parser,$parser2)');
    # TEST
    $open2_counter->test(2, 'expand_include for $parser2 out of ($parser,$parser2)');
    # TEST
    ok($dom1, '$dom1 was returned');
    # TEST
    ok($dom2, '$dom2 was returned');

    my $val1  = ( $dom1->findnodes( "/x/xml/text()") )[0]->string_value();
    my $val2  = ( $dom2->findnodes( "/x/xml/text()") )[0]->string_value();

    $val1 =~ s/^\s*|\s*$//g;
    $val2 =~ s/^\s*|\s*$//g;

    # TEST

    is( $val1, "test", ' TODO : Add test name' );
    # TEST
    is( $val2, "test 4", ' TODO : Add test name' );
}

chdir("example/complex") || die "chdir: $!";

my $str = slurp('complex.xml');

{
    # tests if callbacks are called correctly within DTDs
    my $parser2 = XML::LibXML->new();
    $parser2->expand_xinclude( 1 );
    my $dom = $parser2->parse_string($str);
    # TEST
    ok($dom, '$dom was init.');
}


$XML::LibXML::match_cb = $match1_global_counter->cb();
$XML::LibXML::open_cb  = $open1_global_counter->cb();
$XML::LibXML::read_cb  = $read1_global_counter->cb();
$XML::LibXML::close_cb = $close1_global_counter->cb();

{
    # tests if global callbacks are working
    my $parser = XML::LibXML->new();
    # TEST
    ok($parser, '$parser was init');

    # TEST
    ok($parser->parse_string($str), 'parse_string returns a true value.');

    # TEST
    $open1_global_counter->test(3, 'open1 for global counter.');

    # TEST
    $match1_global_counter->test(3, 'match1 for global callback.');

    # TEST
    $close1_global_counter->test(3, 'close1 for global callback.');

    # TEST
    $read1_global_counter->test(3, 'read1 for global counter.');
}

sub match2 {
    # warn "match2: $_[0]\n";
    return 1;
}

sub close2 {
    # warn "close2 $_[0]\n";
    if ( $_[0] ) {
        $_[0]->close();
    }
    return 1;
}

sub read2 {
    # warn "read2!";
    my $rv = undef;
    my $n = 0;
    if ( $_[0] ) {
        $n = $_[0]->read( $rv , $_[1] );
        # warn "read!" if $n > 0;
    }
    return $rv;
}


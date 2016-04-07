
use strict;
use warnings;

use lib './t/lib';

use Counter;

# $Id$

# Should be 14.
use Test::More tests => 14;

use XML::LibXML;
use IO::File;

# --------------------------------------------------------------------- #
# simple test
# --------------------------------------------------------------------- #
my $string = <<EOF;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude"><xml>test<xinclude:include href="/example/test2.xml"/></xml></x>
EOF

my $icb    = XML::LibXML::InputCallback->new();
# TEST
ok($icb, ' TODO : Add test name');

my $match_file_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $uri = shift;
                if ( $uri =~ /^\/example\// ){
                    $inc_cb->();
                    return 1;
                }
                return 0;
            }
        }
    }
);

my $open_file_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $uri = shift;
                open my $file, '<', ".$uri"
                    or die "Cannot open '.$uri'";
                $inc_cb->();
                return $file;
            }
        }
    }
);

my $read_file_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $h   = shift;
                my $buflen = shift;
                my $rv   = undef;

                $inc_cb->();
                my $n = $h->read( $rv , $buflen );

                return $rv;
            }
        }
    }
);

my $close_file_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $h   = shift;
                $inc_cb->();
                $h->close();
                return 1;

            };
        }
    }
);

my $match_hash_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $uri = shift;
                if ( $uri =~ /^\/example\// ){
                    $inc_cb->();
                    return 1;
                }
                return 0;
            }
        }
    }
);

my $open_hash_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $uri = shift;
                my $hash = { line => 0,
                    lines => [ "<foo>", "bar", "<xsl/>", "..", "</foo>" ],
                };
                $inc_cb->();

                return $hash;
            }
        }
    }
);

my $close_hash_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $h   = shift;
                undef $h;
                $inc_cb->();

                return;
            }
        }
    }
);

my $read_hash_counter = Counter->new(
    {
        gen_cb => sub {
            my $inc_cb = shift;

            sub {
                my $h   = shift;
                my $buflen = shift;

                my $id = $h->{line};
                $h->{line} += 1;
                my $rv= $h->{lines}->[$id];

                $rv = "" unless defined $rv;

                $inc_cb->();

                return $rv;
            }
        }
    }
);

$icb->register_callbacks( [ $match_file_counter->cb(), $open_file_counter->cb(),
                            $read_file_counter->cb(), $close_file_counter->cb() ] );

my $parser = XML::LibXML->new();
$parser->expand_xinclude(1);
$parser->input_callbacks($icb);
my $doc = $parser->parse_string($string);

# TEST
$match_file_counter->test(1, 'match_file matched once.');

# TEST
$open_file_counter->test(1, 'open_file called once.');

# TEST
$read_file_counter->test(2, 'read_file called twice.');

# TEST
$close_file_counter->test(1, 'close_file called once.');

# TEST
ok($doc, ' TODO : Add test name');
# TEST

is($doc->string_value(),"test..", ' TODO : Add test name');

my $icb2    = XML::LibXML::InputCallback->new();

# TEST
ok($icb2, ' TODO : Add test name');

$icb2->register_callbacks( [ $match_hash_counter->cb(), $open_hash_counter->cb(),
                             $read_hash_counter->cb(), $close_hash_counter->cb() ] );

$parser->input_callbacks($icb2);
$doc = $parser->parse_string($string);

# TEST
$match_hash_counter->test(1, 'match_hash matched once.');

# TEST
$open_hash_counter->test(1, 'open_hash called once.');

# TEST
$read_hash_counter->test(6, 'read_hash called six times.');

# TEST
$close_hash_counter->test(1, 'close_hash called once.');

# TEST
ok($doc, ' TODO : Add test name');

# TEST

is($doc->string_value(),"testbar..", ' TODO : Add test name');


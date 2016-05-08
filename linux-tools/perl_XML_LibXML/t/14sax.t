use strict;
use warnings;

use lib './t/lib';

use Counter;
use Stacker;

# should be 31.
use Test::More tests => 31;

# BEGIN { plan tests => 55 }

use XML::LibXML;
use XML::LibXML::SAX;
use XML::LibXML::SAX::Parser;
use XML::LibXML::SAX::Builder;
use XML::SAX;
use IO::File;
# TEST
ok(1, 'Loaded');

sub _create_simple_counter {
    return Counter->new(
        {
            gen_cb => sub {
                my $inc_cb = shift;

                sub {
                    $inc_cb->();
                    return;
                }
            }
        }
    );
}

my $SAXTester_start_document_counter = _create_simple_counter();
my $SAXTester_end_document_counter = _create_simple_counter();

my $SAXTester_start_element_stacker = Stacker->new(
    {
        gen_cb => sub {
            my $push_cb = shift;
            return sub {
                my $el = shift;

                $push_cb->(
                    ($el->{LocalName} =~ m{\A(?:dromedaries|species|humps|disposition|legs)\z})
                    ? 'true'
                    : 'false'
                );

                return;
            };
        },
    }
);

my $SAXNSTester_start_element_stacker = Stacker->new(
    {
        gen_cb => sub {
            my $push_cb = shift;
            return sub {
                my $node = shift;

                $push_cb->(
                    scalar($node->{NamespaceURI} =~ /^urn:/)
                    ? 'true'
                    : 'false'
                );

                return;
            };
        },
    }
);

my $SAXNS2Tester_start_element_stacker = Stacker->new(
    {
        gen_cb => sub {
            my $push_cb = shift;
            return sub {
                my $elt = shift;

                if ($elt->{Name} eq "b")
                {
                    $push_cb->(
                        ($elt->{NamespaceURI} eq "xml://A") ? 'true' : 'false'
                    );
                }

                return;
            };
        },
    }
);


sub _create_urn_stacker
{
    return
    Stacker->new(
        {
            gen_cb => sub {
                my $push_cb = shift;
                return sub {
                    my $node = shift;

                    $push_cb->(
                        ($node->{NamespaceURI} =~ /\A(?:urn:camels|urn:mammals|urn:a)\z/)
                        ? 'true'
                        : 'false'
                    );

                    return;
                };
            },
        }
    );
}

my $SAXNSTester_start_prefix_mapping_stacker = _create_urn_stacker();
my $SAXNSTester_end_prefix_mapping_stacker = _create_urn_stacker();

# TEST
ok(XML::SAX->add_parser(q(XML::LibXML::SAX::Parser)), 'add_parser is successful.');

local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::Parser';

my $parser;
{
    my $sax = SAXTester->new;
    # TEST
    ok($sax, ' TODO : Add test name');

    my $str = join('', IO::File->new("example/dromeds.xml")->getlines);
    my $doc = XML::LibXML->new->parse_string($str);
    # TEST
    ok($doc, ' TODO : Add test name');

    my $generator = XML::LibXML::SAX::Parser->new(Handler => $sax);
    # TEST
    ok($generator, ' TODO : Add test name');

    $generator->generate($doc); # start_element*10

    # TEST
    $SAXTester_start_element_stacker->test(
        [(qw(true)) x 10],
        'start_element was successful 10 times.',
    );
    # TEST
    $SAXTester_start_document_counter->test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter->test(1, 'end_document called once.');

    my $builder = XML::LibXML::SAX::Builder->new();
    # TEST
    ok($builder, ' TODO : Add test name');
    my $gen2 = XML::LibXML::SAX::Parser->new(Handler => $builder);
    my $dom2 = $gen2->generate($doc);
    # TEST
    ok($dom2, ' TODO : Add test name');

    # TEST
    is($dom2->toString, $str, ' TODO : Add test name');
    # warn($dom2->toString);

########### XML::SAX Tests ###########
    $parser = XML::SAX::ParserFactory->parser(Handler => $sax);
    # TEST
    ok($parser, ' TODO : Add test name');
    $parser->parse_uri("example/dromeds.xml"); # start_element*10

    # TEST
    $SAXTester_start_element_stacker->test(
        [(qw(true)) x 10],
        'parse_uri(): start_element was successful 10 times.',
    );
    # TEST
    $SAXTester_start_document_counter->test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter->test(1, 'end_document called once.');

    $parser->parse_string(<<EOT); # start_element*1
<?xml version='1.0' encoding="US-ASCII"?>
<dromedaries one="1" />
EOT
    # TEST
    $SAXTester_start_element_stacker->test(
        [qw(true)],
        'parse_string() : start_element was successful 1 times.',
    );
    # TEST
    $SAXTester_start_document_counter->test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter->test(1, 'end_document called once.');
}

{
    my $sax = SAXNSTester->new;
    # TEST
    ok($sax, ' TODO : Add test name');

    $parser->set_handler($sax);

    $parser->parse_uri("example/ns.xml");

    # TEST
    $SAXNSTester_start_element_stacker->test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester elements.',
    );
    # TEST
    $SAXNSTester_start_prefix_mapping_stacker->test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester start_prefix_mapping.',
    );
    # TEST
    $SAXNSTester_end_prefix_mapping_stacker->test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester end_prefix_mapping.',
    );
}

########### Namespace test ( empty namespaces ) ########

{
    my $h = "SAXNS2Tester";
    my $xml = "<a xmlns='xml://A'><b/></a>";
    my @tests = (
sub {
    XML::LibXML::SAX        ->new( Handler => $h )->parse_string( $xml );
    # TEST
    $SAXNS2Tester_start_element_stacker->test([qw(true)], 'XML::LibXML::SAX');
},

sub {
    XML::LibXML::SAX::Parser->new( Handler => $h )->parse_string( $xml );
    # TEST
    $SAXNS2Tester_start_element_stacker->test([qw(true)], 'XML::LibXML::SAX::Parser');
},
);

    $_->() for @tests;


}


########### Error Handling ###########
{
  my $xml = '<foo><bar/><a>Text</b></foo>';

  my $handler = SAXErrorTester->new;

  foreach my $pkg (qw(XML::LibXML::SAX::Parser XML::LibXML::SAX)) {
    undef $@;
    eval {
      $pkg->new(Handler => $handler)->parse_string($xml);
    };
    # TEST*2
    ok($@, ' TODO : Add test name'); # We got an error
  }

  $handler = SAXErrorCallbackTester->new;
  eval { XML::LibXML::SAX->new(Handler => $handler )->parse_string($xml) };
  # TEST
  ok($@, ' TODO : Add test name'); # We got an error
  # TEST
  ok( $handler->{fatal_called}, ' TODO : Add test name' );

}

########### XML::LibXML::SAX::parse_chunk test ###########

{
  my $chunk = '<app>LOGOUT</app><bar/>';
  my $builder = XML::LibXML::SAX::Builder->new( Encoding => 'UTF-8' );
  my $parser = XML::LibXML::SAX->new( Handler => $builder );
  $parser->start_document();
  $builder->start_element({Name=>'foo'});
  $parser->parse_chunk($chunk);
  $parser->parse_chunk($chunk);
  $builder->end_element({Name=>'foo'});
  $parser->end_document();
  # TEST
  is($builder->result()->documentElement->toString(), '<foo>'.$chunk.$chunk.'</foo>', ' TODO : Add test name');
}


######## TEST error exceptions ##############
{

  package MySAXHandler;
  use strict;
  use warnings;
  use base 'XML::SAX::Base';
  use Carp;
  sub start_element {
    my( $self, $elm) = @_;
    if ( $elm->{LocalName} eq 'TVChannel' ) {
      die bless({ Message => "My exception"},"MySAXException");
    }
  }
}
{
  use strict;
  use warnings;
  my $parser = XML::LibXML::SAX->new( Handler => MySAXHandler->new( )) ;
  eval { $parser->parse_string( <<'EOF' ) };
<TVChannel TVChannelID="71" TVChannelName="ARD">
        <Moin>Moin</Moin>
</TVChannel>
EOF
  # TEST
  is(ref($@), 'MySAXException', ' TODO : Add test name');
  # TEST
  is(ref($@) && $@->{Message}, "My exception", ' TODO : Add test name');
}
########### Helper class #############

package SAXTester;
use Test::More;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub start_document {

  $SAXTester_start_document_counter->cb()->();

  return;
}

sub end_document {
    $SAXTester_end_document_counter->cb()->();
    return;
}

sub start_element {
    my ($self, $el) = @_;

    $SAXTester_start_element_stacker->cb()->($el);

    # foreach my $attr (keys %{$el->{Attributes}}) {
    #   warn("Attr: $attr = $el->{Attributes}->{$attr}\n");
    # }
    # warn("start_element: $el->{Name}\n");

    return;
}

sub end_element {
  my ($self, $el) = @_;
  # warn("end_element: $el->{Name}\n");
}

sub characters {
  my ($self, $chars) = @_;
  # warn("characters: $chars->{Data}\n");
}

1;

package SAXNSTester;
use Test::More;

sub new {
    bless {}, shift;
}

sub start_element {
    my ($self, $node) = @_;

    $SAXNSTester_start_element_stacker->cb()->($node);

    return;
}

sub end_element {
    my ($self, $node) = @_;
    # warn("end_element: $node->{Name}\n");
}

sub start_prefix_mapping {
    my ($self, $node) = @_;

    $SAXNSTester_start_prefix_mapping_stacker->cb()->($node);

    return;
}

sub end_prefix_mapping {
    my ($self, $node) = @_;

    $SAXNSTester_end_prefix_mapping_stacker->cb()->($node);

    return;
}

1;

package SAXNS2Tester;
use Test::More;

#sub new {
#    my $class = shift;
#    return bless {}, $class;
#}

sub start_element {
    my $self = shift;
    my ( $elt ) = @_;

    $SAXNS2Tester_start_element_stacker->cb()->($elt);

    return;
}

1;

package SAXErrorTester;
use Test::More;

sub new {
    bless {}, shift;
}

sub end_document {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}

package SAXErrorCallbackTester;
use Test::More;

sub fatal_error {
    $_[0]->{fatal_called} = 1;
}

sub start_element {
    # test if we can do other stuff
    XML::LibXML->new->parse_string("<foo/>");
    return;
}
sub new {
    bless {}, shift;
}

sub end_document {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}


1;

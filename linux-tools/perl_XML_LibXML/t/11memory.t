use strict;
use warnings;

use lib './t/lib';
use TestHelpers;

use Test::More;
use constant TIMES_THROUGH => $ENV{MEMORY_TIMES} || 100_000;

if ($^O ne 'linux')
{
    plan skip_all => 'linux platform only.';
}
elsif (! $ENV{MEMORY_TEST} )
{
    plan skip_all => "developers only (set MEMORY_TEST=1 to run these tests)\n";
}
else
{
    # Should be 25.
    plan tests => 25;
}

use XML::LibXML;
use XML::LibXML::SAX::Builder;
{

#        require Devel::Peek;
        my $peek = 0;

        # TEST
        ok(1, 'Start.');

        # BASELINE
        check_mem(1);

        # MAKE DOC IN SUB
        {
            my $doc = make_doc();
            # TEST
            ok($doc, 'Make doc in sub 1.');
            # TEST
            ok($doc->toString, 'Make doc in sub 1 - toString().');
        }
        check_mem();
        # MAKE DOC IN SUB II
        # same test as the first one. if this still leaks, it's
        # our problem, otherwise it's perl :/
        {
            my $doc = make_doc();
            # TEST
            ok($doc, 'Make doc in sub 2 - doc.');

            # TEST
            ok($doc->toString, 'Make doc in sub 2 - toString()');
        }
        check_mem();

        {
            my $elem = XML::LibXML::Element->new("foo");
            my $elem2= XML::LibXML::Element->new("bar");
            $elem->appendChild($elem2);
            # TEST
            ok( $elem->toString, 'appendChild.' );
        }
        check_mem();

        # SET DOCUMENT ELEMENT
        {
            my $doc2 = XML::LibXML::Document->new();
            make_doc_elem( $doc2 );
            # TEST
            ok( $doc2, 'SetDocElem');
            # TEST
            ok( $doc2->documentElement, 'SetDocElem documentElement.' );
        }
        check_mem();

        # multiple parsers:
        # MULTIPLE PARSERS
        XML::LibXML->new(); # first parser
        check_mem(1);

        for (1..TIMES_THROUGH) {
            my $parser = XML::LibXML->new();
        }
        # TEST
        ok(1, 'Initialise multiple parsers.');

        check_mem();
        # multiple parses
        for (1..TIMES_THROUGH) {
            my $parser = XML::LibXML->new();
            my $dom = $parser->parse_string("<sometag>foo</sometag>");
        }
        # TEST
        ok(1, 'multiple parses');

        check_mem();

        # multiple failing parses
        # MULTIPLE FAILURES
        for (1..TIMES_THROUGH) {
            # warn("$_\n") unless $_ % 100;
            my $parser = XML::LibXML->new();
            eval {
                my $dom = $parser->parse_string("<sometag>foo</somtag>"); # Thats meant to be an error, btw!
            };
        }
        # TEST
        ok(1, 'Multiple failures.');

        check_mem();

        # building custom docs
        my $doc = XML::LibXML::Document->new();
        for (1..TIMES_THROUGH)        {
            my $elem = $doc->createElement('x');

            if($peek) {
                warn("Doc before elem\n");
                # Devel::Peek::Dump($doc);
                warn("Elem alone\n");
                # Devel::Peek::Dump($elem);
            }

            $doc->setDocumentElement($elem);

            if ($peek) {
                warn("Elem after attaching\n");
                # Devel::Peek::Dump($elem);
                warn("Doc after elem\n");
                # Devel::Peek::Dump($doc);
            }
        }
        if ($peek) {
            warn("Doc should be freed\n");
            # Devel::Peek::Dump($doc);
        }
        # TEST
        ok(1, 'customDocs');
        check_mem();

        {
            my $doc = XML::LibXML->createDocument;
            for (1..TIMES_THROUGH)        {
                make_doc2( $doc );
            }
        }
        # TEST
        ok(1, 'customDocs No. 2');
        check_mem();

        # DTD string parsing

        my $dtdstr = slurp('example/test.dtd');
        $dtdstr =~ s/\r//g;
        $dtdstr =~ s/[\r\n]*$//;

        # TEST

        ok($dtdstr, '$dtdstr');

        for ( 1..TIMES_THROUGH ) {
            my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
        }
        # TEST
        ok(1, 'after dtdstr');
        check_mem();

        # DTD URI parsing
        # parse a DTD from a SYSTEM ID
        for ( 1..TIMES_THROUGH ) {
            my $dtd = XML::LibXML::Dtd->new('ignore', 'example/test.dtd');
        }
        # TEST
        ok(1, 'DTD URI parsing.');
        check_mem();

        # Document validation
        {
            # is_valid()
            my $dtd = XML::LibXML::Dtd->parse_string($dtdstr);
            my $xml;
            eval {
                local $SIG{'__WARN__'} = sub { };
                $xml = XML::LibXML->new->parse_file('example/article_bad.xml');
            };
            for ( 1..TIMES_THROUGH ) {
                my $good;
                eval {
                    local $SIG{'__WARN__'} = sub { };
                    $good = $xml->is_valid($dtd);
                };
            }
            # TEST
            ok(1, 'is_valid()');
            check_mem();

            print "# validate() \n";
            for ( 1..TIMES_THROUGH ) {
                eval {
                    local $SIG{'__WARN__'} = sub { };
                    $xml->validate($dtd);
                };
            }
            # TEST
            ok(1, 'validate()');
            check_mem();

        }

        print "# FIND NODES \n";
        my $xml=<<'dromeds.xml';
<?xml version="1.0" encoding="UTF-8"?>
<dromedaries>
    <species name="Camel">
      <humps>1 or 2</humps>
      <disposition>Cranky</disposition>
    </species>
    <species name="Llama">
      <humps>1 (sort of)</humps>
      <disposition>Aloof</disposition>
    </species>
    <species name="Alpaca">
      <humps>(see Llama)</humps>
      <disposition>Friendly</disposition>
    </species>
</dromedaries>
dromeds.xml

        {
            # my $str = "<foo><bar><foo/></bar></foo>";
            my $str = $xml;
            my $doc = XML::LibXML->new->parse_string( $str );
            for ( 1..TIMES_THROUGH ) {
                 processMessage($xml, '/dromedaries/species' );
#                my @nodes = $doc->findnodes("/foo/bar/foo");
            }
            # TEST
            ok(1, 'after processMessage');
            check_mem();

        }

        {
            my $str = "<foo><bar><foo/></bar></foo>";
            my $doc = XML::LibXML->new->parse_string( $str );
            for ( 1..TIMES_THROUGH ) {
                my $nodes = $doc->find("/foo/bar/foo");
            }
            # TEST
            ok(1, '->find.');
            check_mem();

        }

#        {
#            print "# ENCODING TESTS \n";
#            my $string = "test ä ø is a test string to test iso encoding";
#            my $encstr = encodeToUTF8( "iso-8859-1" , $string );
#            for ( 1..TIMES_THROUGH ) {
#                my $str = encodeToUTF8( "iso-8859-1" , $string );
#            }
#            ok(1);
#            check_mem();

#            for ( 1..TIMES_THROUGH ) {
#                my $str = encodeToUTF8( "iso-8859-2" , "abc" );
#            }
#            ok(1);
#            check_mem();
#
#            for ( 1..TIMES_THROUGH ) {
#                my $str = decodeFromUTF8( "iso-8859-1" , $encstr );
#            }
#            ok(1);
#            check_mem();
#        }
        {
            note("NAMESPACE TESTS");

            my $string = '<foo:bar xmlns:foo="bar"><foo:a/><foo:b/></foo:bar>';

            my $doc = XML::LibXML->new()->parse_string( $string );

            for (1..TIMES_THROUGH) {
                my @ns = $doc->documentElement()->getNamespaces();
                # warn "ns : " . $_->localname . "=>" . $_->href foreach @ns;
                my $prefix = $_->localname foreach @ns;
                my $name = $doc->documentElement->nodeName;
            }
            check_mem();
            # TEST
            ok(1, 'namespace tests.');
        }

        {
            note('SAX PARSER');

        my %xmlStrings = (
            "SIMPLE"      => "<xml1><xml2><xml3></xml3></xml2></xml1>",
            "SIMPLE TEXT" => "<xml1> <xml2>some text some text some text </xml2> </xml1>",
            "SIMPLE COMMENT" => "<xml1> <xml2> <!-- some text --> <!-- some text --> <!--some text--> </xml2> </xml1>",
            "SIMPLE CDATA" => "<xml1> <xml2><![CDATA[some text some text some text]]></xml2> </xml1>",
            "SIMPLE ATTRIBUTE" => '<xml1  attr0="value0"> <xml2 attr1="value1"></xml2> </xml1>',
            "NAMESPACES SIMPLE" => '<xm:xml1 xmlns:xm="foo"><xm:xml2/></xm:xml1>',
            "NAMESPACES ATTRIBUTE" => '<xm:xml1 xmlns:xm="foo"><xm:xml2 xm:foo="bar"/></xm:xml1>',
        );

            my $handler = sax_null->new;
            my $parser  = XML::LibXML->new;
            $parser->set_handler( $handler );

            check_mem();

            foreach my $key ( keys %xmlStrings )  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    my $doc = $parser->parse_string( $xmlStrings{$key} );
                }

                check_mem();
            }
            # TEST
            ok (1, 'SAX PARSER');
        }

        {
            note('PUSH PARSER');

        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>","<xml2><xml3></xml3></xml2>","</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ","<xml2>some text some text some text"," </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1","> <xml2> <!","-- some text --> <!-- some text --> <!--some text-","-> </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ","<xml2><!","[CDATA[some text some text some text]","]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ','attr0="value0"> <xml2 attr1="value1"></xml2>',' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x','m="foo"><xm:xml2','/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">','<xm:xml2 xm:foo="bar"/></xm',':xml1>'],
        );

            my $handler = sax_null->new;
            my $parser  = XML::LibXML->new;

            check_mem();
       if(0) {
            foreach my $key ( keys %xmlStrings )  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    map { $parser->push( $_ ) } @{$xmlStrings{$key}};
                    my $doc = $parser->finish_push();
                }

                check_mem();
            }
            # Cancelled TEST
            ok(1, ' TODO : Add test name');
        }
            my %xmlBadStrings = (
                "SIMPLE"      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>","</xml2>", "</xml1>"],
                "SIMPLE TEXT" => ["<xml1> ","some text some text some text","</xml2>"],
                "SIMPLE CDATA"=> ["<xml1> ","<!","[CDATA[some text some text some text]","</xml1>"],
                "SIMPLE JUNK" => ["<xml1/> ","junk"],
            );

            note('BAD PUSHED DATA');
            foreach my $key ( "SIMPLE","SIMPLE2", "SIMPLE TEXT","SIMPLE CDATA","SIMPLE JUNK" )  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    eval {map { $parser->push( $_ ) } @{$xmlBadStrings{$key}};};
                    eval {my $doc = $parser->finish_push();};
                }

                check_mem();
            }
            # TEST
            ok(1, 'BAD PUSHED DATA');
        }

        {
            note('SAX PUSH PARSER');

            my $handler = sax_null->new;
            my $parser  = XML::LibXML->new;
            $parser->set_handler( $handler );
            check_mem();


        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>","<xml2><xml3></xml3></xml2>","</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ","<xml2>some text some text some text"," </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1","> <xml2> <!","-- some text --> <!-- some text --> <!--some text-","-> </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ","<xml2><!","[CDATA[some text some text some text]","]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ','attr0="value0"> <xml2 attr1="value1"></xml2>',' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x','m="foo"><xm:xml2','/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">','<xm:xml2 xm:foo="bar"/></xm',':xml1>'],
        );

            foreach my $key ( keys %xmlStrings )  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    eval {map { $parser->push( $_ ) } @{$xmlStrings{$key}};};
                    eval {my $doc = $parser->finish_push();};
                }

                check_mem();
            }
            # TEST
            ok(1, 'SAX PUSH PARSER');

            note('BAD PUSHED DATA');

            my %xmlBadStrings = (
                "SIMPLE "      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>","</xml2>", "</xml1>"],
                "SIMPLE TEXT"  => ["<xml1> ","some text some text some text","</xml2>"],
                "SIMPLE CDATA" => ["<xml1> ","<!","[CDATA[some text some text some text]","</xml1>"],
                "SIMPLE JUNK"  => ["<xml1/> ","junk"],
            );

            foreach my $key ( keys %xmlBadStrings )  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    eval {map { $parser->push( $_ ) } @{$xmlBadStrings{$key}};};
                    eval {my $doc = $parser->finish_push();};
                }

                check_mem();
            }
            # TEST
            ok(1, 'BAD PUSHED DATA');
        }
}

sub processMessage {
      my ($msg, $xpath) = @_;
      my $parser = XML::LibXML->new();

      my $doc  = $parser->parse_string($msg);
      my $elm  = $doc->getDocumentElement;
      my $node = $doc->findnodes($xpath);
      my $text = $node->to_literal->value;
#      undef $doc;   # comment this line to make memory leak much worse
#      undef $parser;
}

sub make_doc {
    # code taken from an AxKit XSP generated page
    my ($r, $cgi) = @_;
    my $document = XML::LibXML::Document->createDocument("1.0", "UTF-8");
    # warn("document: $document\n");
    my ($parent);

    {
        my $elem = $document->createElement(q(p));
        $document->setDocumentElement($elem);
        $parent = $elem;
    }

    $parent->setAttribute("xmlns:" . q(param), q(http://axkit.org/XSP/param));

    {
        my $elem = $document->createElementNS(q(http://axkit.org/XSP/param),q(param:foo),);
        $parent->appendChild($elem);
        $parent = $elem;
    }

    $parent = $parent->parentNode;
    # warn("parent now: $parent\n");
    $parent = $parent->parentNode;
    # warn("parent now: $parent\n");

    return $document
}

sub make_doc2 {
    my $docA = shift;
    my $docB = XML::LibXML::Document->new;
    my $e1   = $docB->createElement( "A" );
    my $e2   = $docB->createElement( "B" );
    $e1->appendChild( $e2 );
    $docA->setDocumentElement( $e1 );
}

sub check_mem {
    my $initialise = shift;
    # Log Memory Usage
    local $^W;
    my %mem;
    if (open(my $FH, '<', '/proc/self/status')) {
        my $units;
        while (<$FH>) {
            if (/^VmSize.*?(\d+)\W*(\w+)$/) {
                $mem{Total} = $1;
                $units = $2;
            }
            if (/^VmRSS:.*?(\d+)/) {
                $mem{Resident} = $1;
            }
        }
        close ($FH);

        if ($LibXML::TOTALMEM != $mem{Total}) {
            warn("LEAK! : ", $mem{Total} - $LibXML::TOTALMEM, " $units\n") unless $initialise;
            $LibXML::TOTALMEM = $mem{Total};
        }

        note("# Mem Total: $mem{Total} $units, Resident: $mem{Resident} $units\n");
    }
}

# some tests for document fragments
sub make_doc_elem {
    my $doc = shift;
    my $dd = XML::LibXML::Document->new();
    my $node1 = $doc->createElement('test1');
    my $node2 = $doc->createElement('test2');
    $doc->setDocumentElement( $node1 );
}

package sax_null;

# require Devel::Peek;
# use Data::Dumper;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub start_document {
    my $self = shift;
    my $dummy = shift;
}

sub xml_decl {
    my $self = shift;
    my $dummy = shift;
}

sub start_element {
    my $self = shift;
    my $dummy = shift;
    # warn Dumper( $dummy );
}

sub end_element {
    my $self = shift;
    my $dummy = shift;
}

sub start_cdata {
    my $self = shift;
    my $dummy = shift;
}

sub end_cdata {
    my $self = shift;
    my $dummy = shift;
}

sub start_prefix_mapping {
    my $self = shift;
    my $dummy = shift;
}

sub end_prefix_mapping {
    my $self = shift;
    my $dummy = shift;
}

sub characters {
    my $self = shift;
    my $dummy = shift;
}

sub comment {
    my $self = shift;
    my $dummy = shift;
}


sub end_document {
    my $self = shift;
    my $dummy = shift;
}

sub error {
    my $self = shift;
    my $msg  = shift;
    die( $msg );
}

1;

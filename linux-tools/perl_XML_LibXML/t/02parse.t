# $Id$

##
# this test checks the parsing capabilities of XML::LibXML
# it relies on the success of t/01basic.t

use strict;
use warnings;

use Test::More tests => 531;
use IO::File;

use XML::LibXML::Common qw(:libxml);
use XML::LibXML::SAX;
use XML::LibXML::SAX::Builder;

use constant XML_DECL => "<?xml version=\"1.0\"?>\n";

use Errno qw(ENOENT);

##
# test values
my @goodWFStrings = (
'<foobar/>',
'<foobar></foobar>',
XML_DECL . "<foobar></foobar>",
'<?xml version="1.0" encoding="UTF-8"?>'."\n<foobar></foobar>",
'<?xml version="1.0" encoding="ISO-8859-1"?>'."\n<foobar></foobar>",
XML_DECL. "<foobar> </foobar>\n",
XML_DECL. '<foobar><foo/></foobar> ',
XML_DECL. '<foobar> <foo/> </foobar> ',
XML_DECL. '<foobar><![CDATA[<>&"\']]></foobar>',
XML_DECL. '<foobar>&lt;&gt;&amp;&quot;&apos;</foobar>',
XML_DECL. '<foobar>&#x20;&#160;</foobar>',
XML_DECL. '<!--comment--><foobar>foo</foobar>',
XML_DECL. '<foobar>foo</foobar><!--comment-->',
XML_DECL. '<foobar>foo<!----></foobar>',
XML_DECL. '<foobar foo="bar"/>',
XML_DECL. '<foobar foo="\'bar>"/>',
#XML_DECL. '<bar:foobar foo="bar"><bar:foo/></bar:foobar>',
#'<bar:foobar/>'
                    );

my @goodWFNSStrings = (
XML_DECL. '<foobar xmlns:bar="xml://foo" bar:foo="bar"/>'."\n",
XML_DECL. '<foobar xmlns="xml://foo" foo="bar"><foo/></foobar>'."\n",
XML_DECL. '<bar:foobar xmlns:bar="xml://foo" foo="bar"><foo/></bar:foobar>'."\n",
XML_DECL. '<bar:foobar xmlns:bar="xml://foo" foo="bar"><bar:foo/></bar:foobar>'."\n",
XML_DECL. '<bar:foobar xmlns:bar="xml://foo" bar:foo="bar"><bar:foo/></bar:foobar>'."\n",
                      );

my @goodWFDTDStrings = (
XML_DECL. '<!DOCTYPE foobar ['."\n".'<!ENTITY foo " test ">'."\n".']>'."\n".'<foobar>&foo;</foobar>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;</foobar>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;&gt;</foobar>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar=&quot;foo&quot;">]><foobar>&foo;&gt;</foobar>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;&gt;</foobar>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar foo="&foo;"/>',
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar foo="&gt;&foo;"/>',
                       );

my @badWFStrings = (
"",                                        # totally empty document
XML_DECL,                                  # only XML Declaration
"<!--ouch-->",                             # comment only is like an empty document
'<!DOCTYPE ouch [<!ENTITY foo "bar">]>',   # no good either ...
"<ouch>",                                  # single tag (tag mismatch)
"<ouch/>foo",                              # trailing junk
"foo<ouch/>",                              # leading junk
"<ouch foo=bar/>",                         # bad attribute
'<ouch foo="bar/>',                        # bad attribute
"<ouch>&</ouch>",                          # bad char
"<ouch>&#0x20;</ouch>",                    # bad char
"<foobär/>",                               # bad encoding
"<ouch>&foo;</ouch>",                      # undefind entity
"<ouch>&gt</ouch>",                        # unterminated entity
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar &foo;="ouch"/>',          # bad placed entity
XML_DECL. '<!DOCTYPE foobar [<!ENTITY foo "bar=&quot;foo&quot;">]><foobar &foo;/>', # even worse
"<ouch><!---></ouch>",                     # bad comment
'<ouch><!-----></ouch>',                   # bad either... (is this conform with the spec????)
                    );

    my %goodPushWF = (
single1 => ['<foobar/>'],
single2 => ['<foobar>','</foobar>'],
single3 => [ XML_DECL, "<foobar>", "</foobar>" ],
single4 => ["<foo", "bar/>"],
single5 => ["<", "foo","bar", "/>"],
single6 => ['<?xml version="1.0" encoding="UTF-8"?>',"\n<foobar/>"],
single7 => ['<?xml',' version="1.0" ','encoding="UTF-8"?>',"\n<foobar/>"],
single8 => ['<foobar', ' foo=', '"bar"', '/>'],
single9 => ['<?xml',' versio','n="1.0" ','encodi','ng="U','TF8"?>',"\n<foobar/>"],
multiple1 => [ '<foobar>','<foo/>','</foobar> ', ],
multiple2 => [ '<foobar','><fo','o','/><','/foobar> ', ],
multiple3 => [ '<foobar>','<![CDATA[<>&"\']]>','</foobar>'],
multiple4 => [ '<foobar>','<![CDATA[', '<>&', ']]>', '</foobar>' ],
multiple5 => [ '<foobar>','<!','[CDA','TA[', '<>&', ']]>', '</foobar>' ],
multiple6 => ['<foobar>','&lt;&gt;&amp;&quot;&apos;','</foobar>'],
multiple6 => ['<foobar>','&lt',';&','gt;&a','mp;','&quot;&ap','os;','</foobar>'],
multiple7 => [ '<foobar>', '&#x20;&#160;','</foobar>' ],
multiple8 => [ '<foobar>', '&#x','20;&#1','60;','</foobar>' ],
multiple9 => [ '<foobar>','moo','moo','</foobar> ', ],
multiple10 => [ '<foobar>','moo','</foobar> ', ],
comment1  => [ '<!--comment-->','<foobar/>' ],
comment2  => [ '<foobar/>','<!--comment-->' ],
comment3  => [ '<!--','comment','-->','<foobar/>' ],
comment4  => [ '<!--','-->','<foobar/>' ],
comment5  => [ '<foobar>fo','o<!---','-><','/foobar>' ],
attr1     => [ '<foobar',' foo="bar"/>'],
attr2     => [ '<foobar',' foo','="','bar','"/>'],
attr3     => [ '<foobar',' fo','o="b','ar"/>'],
#prefix1   => [ '<bar:foobar/>' ],
#prefix2   => [ '<bar',':','foobar/>' ],
#prefix3   => [ '<ba','r:fo','obar/>' ],
ns1       => [ '<foobar xmlns:bar="xml://foo"/>' ],
ns2       => [ '<foobar ','xmlns:bar="xml://foo"','/>' ],
ns3       => [ '<foo','bar x','mlns:b','ar="foo"/>' ],
ns4       => [ '<bar:foobar xmlns:bar="xml://foo"/>' ],
ns5       => [ '<bar:foo','bar xm','lns:bar="fo','o"/>' ],
ns6       => [ '<bar:fooba','r xm','lns:ba','r="foo"','><bar',':foo/','></bar'.':foobar>'],
dtd1      => [XML_DECL, '<!DOCTYPE ','foobar [','<!ENT','ITY foo " test ">',']>','<foobar>&f','oo;</foobar>',],
dtd2      => [XML_DECL, '<!DOCTYPE ','foobar [','<!ENT','ITY foo " test ">',']>','<foobar>&f','oo;&gt;</foobar>',],
                    );

my $goodfile = "example/dromeds.xml";
my $badfile1 = "example/bad.xml";
my $badfile2 = "does_not_exist.xml";

my $parser = XML::LibXML->new();

# 1 NON VALIDATING PARSER
# 1.1 WELL FORMED STRING PARSING
# 1.1.1 DEFAULT VALUES

{
    foreach my $str ( @goodWFStrings,@goodWFNSStrings,@goodWFDTDStrings ) {
        my $doc = $parser->parse_string($str);
        isa_ok($doc, 'XML::LibXML::Document');
    }
}

eval { my $fail = $parser->parse_string(undef); };
like($@, qr/^Empty String at/, "parses undef string with an error");

foreach my $str ( @badWFStrings ) {
    eval { my $fail = $parser->parse_string($str); };

    ok($@, "Error thrown passing '" . shorten_string($str)  . "'");
}


# 1.1.2 NO KEEP BLANKS

$parser->keep_blanks(0);

{
    foreach my $str ( @goodWFStrings,@goodWFNSStrings,@goodWFDTDStrings ) {
	my $doc = $parser->parse_string($str);
        isa_ok($doc, 'XML::LibXML::Document');
    }
}

eval { my $fail = $parser->parse_string(undef); };
like($@, qr/^Empty String at/, "parses undef string with an error");

foreach my $str ( @badWFStrings ) {
    eval { my $fail = $parser->parse_string($str); };

    ok($@, "Error thrown passing '" . shorten_string($str)  . "'");
}

$parser->keep_blanks(1);

# 1.1.3 EXPAND ENTITIES

$parser->expand_entities(0);

{
    foreach my $str ( @goodWFStrings,@goodWFNSStrings,@goodWFDTDStrings ) {
        my $doc = $parser->parse_string($str);
        isa_ok($doc, 'XML::LibXML::Document');
    }
}

eval { my $fail = $parser->parse_string(undef); };
like($@, qr/^Empty String at/, "parses undef string with an error");

foreach my $str ( @badWFStrings ) {
    eval { my $fail = $parser->parse_string($str); };

    ok($@, "Error thrown passing '" . shorten_string($str)  . "'");
}

$parser->expand_entities(1);

# 1.1.4 PEDANTIC

$parser->pedantic_parser(1);

{
    foreach my $str ( @goodWFStrings,@goodWFNSStrings,@goodWFDTDStrings ) {
        my $doc = $parser->parse_string($str);
	isa_ok($doc, 'XML::LibXML::Document');
    }
}

eval { my $fail = $parser->parse_string(undef); };
like($@, qr/^Empty String at/, "parses undef string with an error");


foreach my $str ( @badWFStrings ) {
    eval { my $fail = $parser->parse_string($str); };
    ok($@, "Error thrown passing '" . shorten_string($str)  . "'");
}

$parser->pedantic_parser(0);

# 1.2 PARSE A FILE

{
    my $doc = $parser->parse_file($goodfile);
    isa_ok($doc, 'XML::LibXML::Document');
}

eval {my $fail = $parser->parse_file($badfile1);};
like($@, qr/^$badfile1:3: parser error : Extra content at the end of the document/, "error parsing $badfile1");

{
    # This is to fix https://rt.cpan.org/Public/Bug/Display.html?id=69248
    # Testing for localised error messages.
    $! = ENOENT;
    my $err_string = "$!";
    $! = 0;

    my $re = qr/\ACould not create file parser context for file "\Q$badfile2\E": \Q$err_string\E/;

    eval { $parser->parse_file($badfile2); };
    like($@, $re, "error parsing non-existent $badfile2");
}

{
    my $str = "<a>    <b/> </a>";
    my $tstr= "<a><b/></a>";
    $parser->keep_blanks(0);
    my $docA = $parser->parse_string($str);
    my $docB = $parser->parse_file("example/test3.xml");
    $XML::LibXML::skipXMLDeclaration = 1;
    is( $docA->toString, $tstr, "xml string round trips as expected");
    is( $docB->toString, $tstr, "test3.xml round trips as expected");
    $XML::LibXML::skipXMLDeclaration = 0;
}

# 1.3 PARSE A HANDLE

my $fh = IO::File->new($goodfile);
isa_ok($fh, 'IO::File');

my $doc = $parser->parse_fh($fh);
isa_ok($doc, 'XML::LibXML::Document');

$fh = IO::File->new($badfile1);
isa_ok($fh, 'IO::File');

eval { my $doc = $parser->parse_fh($fh); };
like($@, qr/^Entity: line 3: parser error : Extra content at the end of the document/, "error parsing bad file from file handle of $badfile1");

$fh = IO::File->new($badfile2);

eval { my $doc = $parser->parse_fh($fh); };
like($@, qr/^Can't use an undefined value as a symbol reference at/, "error parsing bad file from file handle of non-existent $badfile2");

{
    $parser->expand_entities(1);
    my $doc = $parser->parse_file( "example/dtd.xml" );
    my @cn = $doc->documentElement->childNodes;
    is( scalar @cn, 1, "1 child node" );

    $doc = $parser->parse_file( "example/complex/complex2.xml" );
    @cn = $doc->documentElement->childNodes;
    is( scalar @cn, 1, "1 child node" );

    $parser->expand_entities(0);
    $doc = $parser->parse_file( "example/dtd.xml" );
    @cn = $doc->documentElement->childNodes;
    is( scalar @cn, 3, "3 child nodes" );
}

# 1.4 x-include processing

my $goodXInclude = q{
<x>
<xinclude:include
 xmlns:xinclude="http://www.w3.org/2001/XInclude"
 href="test2.xml"/>
</x>
};


my $badXInclude = q{
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xinclude:include href="bad.xml"/>
</x>
};

{
    $parser->base_uri( "example/" );
    $parser->keep_blanks(0);
    my $doc = $parser->parse_string( $goodXInclude );
    isa_ok($doc, 'XML::LibXML::Document');

    my $i;
    eval { $i = $parser->processXIncludes($doc); };
    is( $i, "1", "return value from processXIncludes == 1");

    $doc = $parser->parse_string( $badXInclude );
    $i= undef;
    eval { $i = $parser->processXIncludes($doc); };
    like($@, qr/$badfile1:3: parser error : Extra content at the end of the document/, "error parsing a bad include");

    # auto expand
    $parser->expand_xinclude(1);
    $doc = $parser->parse_string( $goodXInclude );
    isa_ok($doc, 'XML::LibXML::Document');

    $doc = undef;
    eval { $doc = $parser->parse_string( $badXInclude ); };
    like($@, qr/$badfile1:3: parser error : Extra content at the end of the document/, "error parsing $badfile1 in include");
    is($doc, undef, "no doc returned");

    # some bad stuff
    eval{ $parser->processXIncludes(undef); };
    like($@, qr/^No document to process! at/, "Error parsing undef include");

    eval{ $parser->processXIncludes("blahblah"); };
    like($@, qr/^No document to process! at/, "Error parsing bogus include");
}

# 2 PUSH PARSER

{
    my $pparser = XML::LibXML->new();
    # 2.1 PARSING WELLFORMED DOCUMENTS
    foreach my $key ( qw(single1 single2 single3 single4 single5 single6
                         single7 single8 single9 multiple1 multiple2 multiple3
                         multiple4 multiple5 multiple6 multiple7 multiple8
                         multiple9 multiple10 comment1 comment2 comment3
                         comment4 comment5 attr1 attr2 attr3
			 ns1 ns2 ns3 ns4 ns5 ns6 dtd1 dtd2) ) {
        foreach ( @{$goodPushWF{$key}} ) {
            $pparser->parse_chunk( $_ );
        }

        my $doc;
        eval {$doc = $pparser->parse_chunk("",1); };
	is($@, '', "No error parsing $key");
	isa_ok($doc, 'XML::LibXML::Document', "Document came back parsing chunk: ");
    }

    my @good_strings = ("<foo>", "bar", "</foo>" );
    my %bad_strings  = (
                            predocend1   => ["<A>" ],
                            predocend2   => ["<A>", "B"],
                            predocend3   => ["<A>", "<C>"],
                            predocend4   => ["<A>", "<C/>"],
                            postdocend1  => ["<A/>", "<C/>"],
# use with libxml2 2.4.26:  postdocend2  => ["<A/>", "B"],    # libxml2 < 2.4.26 bug
                            postdocend3  => ["<A/>", "BB"],
                            badcdata     => ["<A> ","<!","[CDATA[B]","</A>"],
                            badending1   => ["<A> ","B","</C>"],
                            badending2   => ["<A> ","</C>","</A>"],
                       );

    my $parser = XML::LibXML->new;
    {
        for ( @good_strings ) {
            $parser->parse_chunk( $_ );
        }
        my $doc = $parser->parse_chunk("",1);
        isa_ok($doc, 'XML::LibXML::Document');
    }

    {
        # 2.2 PARSING BROKEN DOCUMENTS
        my $doc;
        foreach my $key ( keys %bad_strings ) {
            $doc = undef;
	    my $bad_chunk;
            foreach ( @{$bad_strings{$key}} ) {
               eval { $parser->parse_chunk( $_ );};
               if ( $@ ) {
                   # if we won't stop here, we will lose the error :|
		   $bad_chunk = $_;
                   last;
               }
            }
            if ( $@ ) {
	        isnt($@, '', "Error found parsing chunk $bad_chunk");
#                $parser->parse_chunk("",1); # will cause no harm anymore, but is still needed
                next;
            }

            eval {
                $doc = $parser->parse_chunk("",1);
            };
            isnt($@, '', "Got an error parsing empty chunk after chunks for $key");
        }

    }

    {
        # 2.3 RECOVERING PUSH PARSER
        $parser->init_push;

        foreach ( "<A>", "B" ) {
            $parser->push( $_);
        }

        my $doc;
        eval {
	       local $SIG{'__WARN__'} = sub { };
	       $doc = $parser->finish_push(1);
	     };
        isa_ok( $doc, 'XML::LibXML::Document' );
    }
}

# 3 SAX PARSER

{
    my $handler = XML::LibXML::SAX::Builder->new();
    my $generator = XML::LibXML::SAX->new( Handler=>$handler );

    my $string  = q{<bar foo="bar">foo</bar>};

    $doc = $generator->parse_string( $string );
    isa_ok( $doc , 'XML::LibXML::Document');

    # 3.1 GENERAL TESTS
    foreach my $str ( @goodWFStrings ) {
        my $doc = $generator->parse_string( $str );
        isa_ok( $doc , 'XML::LibXML::Document');
    }

    # CDATA Sections

    $string = q{<foo><![CDATA[&foo<bar]]></foo>};
    $doc = $generator->parse_string( $string );
    my @cn = $doc->documentElement->childNodes();
    is( scalar @cn, 1, "Child nodes - 1" );
    is( $cn[0]->nodeType, XML_CDATA_SECTION_NODE );
    is( $cn[0]->textContent, "&foo<bar" );
    is( $cn[0]->toString, '<![CDATA[&foo<bar]]>');

    # 3.2 NAMESPACE TESTS

    my $i = 0;
    foreach my $str ( @goodWFNSStrings ) {
        my $doc = $generator->parse_string( $str );
        isa_ok( $doc , 'XML::LibXML::Document');

        # skip the nested node tests until there is a xmlNormalizeNs().
        #ok(1),next if $i > 2;

        is( $doc->toString(), $str );
        $i++
    }

    # DATA CONSISTENCE
    # find out if namespaces are there
    my $string2 = q{<foo xmlns:bar="http://foo.bar">bar<bar:bi/></foo>};

    $doc = $generator->parse_string( $string2 );

    my @attrs = $doc->documentElement->attributes;

    is(scalar @attrs , 1, "1 attribute");
    is( $attrs[0]->nodeType, XML_NAMESPACE_DECL, "Node type: " . XML_NAMESPACE_DECL );

    my $root = $doc->documentElement;

    # bad thing: i have to do some NS normalizing.
    # libxml2 will only do some fixing. this will lead to multiple
    # declarations, if a node with a new namespace is added.

    my $vstring = q{<foo xmlns:bar="http://foo.bar">bar<bar:bi/></foo>};
    # my $vstring = q{<foo xmlns:bar="http://foo.bar">bar<bar:bi xmlns:bar="http://foo.bar"/></foo>};
    is($root->toString, $vstring );

    # 3.3 INTERNAL SUBSETS

    foreach my $str ( @goodWFDTDStrings ) {
        my $doc = $generator->parse_string( $str );
        isa_ok( $doc , 'XML::LibXML::Document');
    }

    # 3.5 PARSE URI
    $doc = $generator->parse_uri( "example/test.xml" );
    isa_ok($doc, 'XML::LibXML::Document');

    # 3.6 PARSE CHUNK


}

# 4 SAXY PUSHER

{
    my $handler = XML::LibXML::SAX::Builder->new();
    my $parser = XML::LibXML->new;

    $parser->set_handler( $handler );
    $parser->push( '<foo/>' );
    my $doc = $parser->finish_push;
    isa_ok($doc , 'XML::LibXML::Document');

    foreach my $key ( keys %goodPushWF ) {
        foreach ( @{$goodPushWF{$key}} ) {
            $parser->push( $_);
        }

        my $doc;
        eval {$doc = $parser->finish_push; };
        isa_ok( $doc , 'XML::LibXML::Document');
    }
}

# 5 PARSE WELL BALANCED CHUNKS
{
    my $MAX_WF_C = 11;
    my $MAX_WB_C = 16;

    my %chunks = (
                    wellformed1  => '<A/>',
                    wellformed2  => '<A></A>',
                    wellformed3  => '<A B="C"/>',
                    wellformed4  => '<A>D</A>',
                    wellformed5  => '<A><![CDATA[D]]></A>',
                    wellformed6  => '<A><!--D--></A>',
                    wellformed7  => '<A><K/></A>',
                    wellformed8  => '<A xmlns="xml://E"/>',
                    wellformed9  => '<F:A xmlns:F="xml://G" F:A="B">D</F:A>',
                    wellformed10 => '<!--D-->',
                    wellformed11  => '<A xmlns:F="xml://E"/>',
                    wellbalance1 => '<A/><A/>',
                    wellbalance2 => '<A></A><A></A>',
                    wellbalance3 => '<A B="C"/><A B="H"/>',
                    wellbalance4 => '<A>D</A><A>I</A>',
                    wellbalance5 => '<A><K/></A><A><L/></A>',
                    wellbalance6 => '<A><![CDATA[D]]></A><A><![CDATA[I]]></A>',
                    wellbalance7 => '<A><!--D--></A><A><!--I--></A>',
                    wellbalance8 => '<F:A xmlns:F="xml://G" F:A="B">D</F:A><J:A xmlns:J="xml://G" J:A="M">D</J:A>',
                    wellbalance9 => 'D<A/>',
                    wellbalance10=> 'D<A/>D',
                    wellbalance11=> 'D<A/><!--D-->',
                    wellbalance12=> 'D<A/><![CDATA[D]]>',
                    wellbalance13=> '<![CDATA[D]]><A/>D',
                    wellbalance14=> '<!--D--><A/>',
                    wellbalance15=> '<![CDATA[D]]>',
                    wellbalance16=> 'D',
                 );

    my @badWBStrings = (
        "",
        "<ouch>",
        "<ouch>bar",
        "bar</ouch>",
        "<ouch/>&foo;", # undefined entity
        "&",            # bad char
        "häh?",         # bad encoding
        "<!--->",       # bad stays bad ;)
        "<!----->",     # bad stays bad ;)
    );


    my $pparser = XML::LibXML->new;

    # 5.1 DOM CHUNK PARSER

    for ( 1..$MAX_WF_C ) {
        my $frag = $pparser->parse_xml_chunk($chunks{'wellformed'.$_});
        isa_ok($frag, 'XML::LibXML::DocumentFragment');
        if ( $frag->nodeType == XML_DOCUMENT_FRAG_NODE
             && $frag->hasChildNodes ) {
            if ( $frag->firstChild->isSameNode( $frag->lastChild ) ) {
                if ( $chunks{'wellformed' . $_} =~ /\<A\>\<\/A\>/ ) {
                    $_--; # because we cannot distinguish between <a/> and <a></a>
                }

                is($frag->toString, $chunks{'wellformed' . $_}, $chunks{'wellformed' . $_} . " is well formed");
                next;
            }
        }
        fail("Unexpected fragment without child nodes");
    }

    for ( 1..$MAX_WB_C ) {
        my $frag = $pparser->parse_xml_chunk($chunks{'wellbalance'.$_});
        isa_ok($frag, 'XML::LibXML::DocumentFragment');
        if ( $frag->nodeType == XML_DOCUMENT_FRAG_NODE
             && $frag->hasChildNodes ) {
            if ( $chunks{'wellbalance'.$_} =~ /<A><\/A>/ ) {
                $_--;
            }
            is($frag->toString, $chunks{'wellbalance'.$_}, $chunks{'wellbalance'.$_} . " is well balanced");
            next;
        }
        fail("Can't test balancedness");
    }

    eval { my $fail = $pparser->parse_xml_chunk(undef); };
    like($@, qr/^Empty String at/, "error parsing undef xml chunk");

    eval { my $fail = $pparser->parse_xml_chunk(""); };
    like($@, qr/^Empty String at/, "error parsing empty xml chunk");

    foreach my $str ( @badWBStrings ) {
        eval { my $fail = $pparser->parse_xml_chunk($str); };
        isnt($@, '', "Error parsing xml chunk: '" . shorten_string($str) . "'");
    }

    {
        # 5.1.1 Segmenation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my $parser = XML::LibXML->new();
        my $doc = $parser->parse_xml_chunk( $sDoc,  undef );
        my $chk = $parser->parse_xml_chunk( $sChunk,undef );

        my $fc = $doc->firstChild;

        $doc->appendChild( $chk );

        is( $doc->toString(), '<C/><D/><A/><B/>', 'No segfault parsing string "<C/><D/><A/><B/>"');
    }

    {
        # 5.1.2 Segmenation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my $parser = XML::LibXML->new();
        my $doc = $parser->parse_xml_chunk( $sDoc,  undef );
        my $chk = $parser->parse_xml_chunk( $sChunk,undef );

        my $fc = $doc->firstChild;

        $doc->insertAfter( $chk, $fc );

        is( $doc->toString(), '<C/><A/><B/><D/>', 'No segfault parsing string "<C/><A/><B/><D/>"');
    }

    {
        # 5.1.3 Segmenation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my $parser = XML::LibXML->new();
        my $doc = $parser->parse_xml_chunk( $sDoc,  undef );
        my $chk = $parser->parse_xml_chunk( $sChunk,undef );

        my $fc = $doc->firstChild;

        $doc->insertBefore( $chk, $fc );

        ok( $doc->toString(), '<A/><B/><C/><D/>' );
    }

    pass("Made it to SAX test without seg fault");

    # 5.2 SAX CHUNK PARSER

    my $handler = XML::LibXML::SAX::Builder->new();
    my $parser = XML::LibXML->new;
    $parser->set_handler( $handler );
    for ( 1..$MAX_WF_C ) {
        my $frag = $parser->parse_xml_chunk($chunks{'wellformed'.$_});
        isa_ok($frag, 'XML::LibXML::DocumentFragment');
        if ( $frag->nodeType == XML_DOCUMENT_FRAG_NODE
             && $frag->hasChildNodes ) {
            if ( $frag->firstChild->isSameNode( $frag->lastChild ) ) {
                if ( $chunks{'wellformed'.$_} =~ /\<A\>\<\/A\>/ ) {
                    $_--;
                }
                is($frag->toString, $chunks{'wellformed'.$_}, $chunks{'wellformed'.$_} . ' is well formed');
                next;
            }
        }
        fail("Couldn't pass well formed test since frag was bad");
    }

    for ( 1..$MAX_WB_C ) {
        my $frag = $parser->parse_xml_chunk($chunks{'wellbalance'.$_});
        isa_ok($frag, 'XML::LibXML::DocumentFragment');
        if ( $frag->nodeType == XML_DOCUMENT_FRAG_NODE
             && $frag->hasChildNodes ) {
            if ( $chunks{'wellbalance'.$_} =~ /<A><\/A>/ ) {
                $_--;
            }
            is($frag->toString, $chunks{'wellbalance'.$_}, $chunks{'wellbalance'.$_} . " is well balanced");
            next;
        }
        fail("Couldn't pass well balanced test since frag was bad");
    }
}

{
    # 6 VALIDATING PARSER

    my %badstrings = (
                    SIMPLE => '<?xml version="1.0"?>'."\n<A/>\n",
                  );
    my $parser = XML::LibXML->new;

    $parser->validation(1);
    my $doc;
    eval { $doc = $parser->parse_string($badstrings{SIMPLE}); };
    isnt($@, '', "Failed to parse SIMPLE bad string");
    my $ql;
}

{
    # 7 LINE NUMBERS

    my $goodxml = <<EOXML;
<?xml version="1.0"?>
<foo>
    <bar/>
</foo>
EOXML

    my $badxml = <<EOXML;
<?xml version="1.0"?>
<!DOCTYPE foo [<!ELEMENT foo EMPTY>]>
<bar/>
EOXML

    my $parser = XML::LibXML->new;
    $parser->validation(1);

    eval { $parser->parse_string( $badxml ); };
    # correct line number may or may not be present
    # depending on libxml2 version
    like($@,  qr/^:[03]:/, "line 03 found in error" );

    $parser->line_numbers(1);
    eval { $parser->parse_string( $badxml ); };
    like($@, qr/^:3:/, "line 3 found in error");

    # switch off validation for the following tests
    $parser->validation(0);

    my $doc;
    eval { $doc = $parser->parse_string( $goodxml ); };

    my $root = $doc->documentElement();
    is( $root->line_number(), 2, "line number is 2");

    my @kids = $root->childNodes();
    is( $kids[1]->line_number(),3, "line number is 3" );

    my $newkid = $root->appendChild( $doc->createElement( "bar" ) );
    is( $newkid->line_number(), 0, "line number is 0");

    $parser->line_numbers(0);
    eval { $doc = $parser->parse_string( $goodxml ); };

    $root = $doc->documentElement();
    is( $root->line_number(), 0, "line number is 0");

    @kids = $root->childNodes();
    is( $kids[1]->line_number(), 0, "line number is 0");
}

SKIP: {
    skip("LibXML version is below 20600", 8) unless ( XML::LibXML::LIBXML_VERSION >= 20600 );
    # 8 Clean Namespaces

    my ( $xsDoc1, $xsDoc2 );
    $xsDoc1 = q{<A:B xmlns:A="http://D"><A:C xmlns:A="http://D"></A:C></A:B>};
    $xsDoc2 = q{<A:B xmlns:A="http://D"><A:C xmlns:A="http://E"/></A:B>};

    my $parser = XML::LibXML->new();
    $parser->clean_namespaces(1);

    my $fn1 = "example/xmlns/goodguy.xml";
    my $fn2 = "example/xmlns/badguy.xml";

    is( $parser->parse_string( $xsDoc1 )->documentElement->toString(),
        q{<A:B xmlns:A="http://D"><A:C/></A:B>} );
    is( $parser->parse_string( $xsDoc2 )->documentElement->toString(),
        $xsDoc2 );

    is( $parser->parse_file( $fn1  )->documentElement->toString(),
        q{<A:B xmlns:A="http://D"><A:C/></A:B>} );
    is( $parser->parse_file( $fn2 )->documentElement->toString() ,
        $xsDoc2 );

    my $fh1 = IO::File->new($fn1);
    my $fh2 = IO::File->new($fn2);

    is( $parser->parse_fh( $fh1  )->documentElement->toString(),
        q{<A:B xmlns:A="http://D"><A:C/></A:B>} );
    is( $parser->parse_fh( $fh2 )->documentElement->toString() ,
        $xsDoc2 );

    my @xaDoc1 = ('<A:B xmlns:A="http://D">','<A:C xmlns:A="h','ttp://D"/>' ,'</A:B>');
    my @xaDoc2 = ('<A:B xmlns:A="http://D">','<A:C xmlns:A="h','ttp://E"/>' , '</A:B>');

    my $doc;

    foreach ( @xaDoc1 ) {
        $parser->parse_chunk( $_ );
    }
    $doc = $parser->parse_chunk( "", 1 );
    is( $doc->documentElement->toString(),
        q{<A:B xmlns:A="http://D"><A:C/></A:B>} );


    foreach ( @xaDoc2 ) {
        $parser->parse_chunk( $_ );
    }
    $doc = $parser->parse_chunk( "", 1 );
    is( $doc->documentElement->toString() ,
        $xsDoc2 );
};


##
# test if external subsets are loaded correctly

{
        my $xmldoc = <<EOXML;
<!DOCTYPE X SYSTEM "example/ext_ent.dtd">
<X>&foo;</X>
EOXML
        my $parser = XML::LibXML->new();

        $parser->load_ext_dtd(1);

        # first time it should work
        my $doc    = $parser->parse_string( $xmldoc );
        is( $doc->documentElement()->string_value(), " test " );

        # second time it must not fail.
        my $doc2   = $parser->parse_string( $xmldoc );
        is( $doc2->documentElement()->string_value(), " test " );
}

##
# Test ticket #7668 xinclude breaks entity expansion
# [CG] removed again, since #7668 claims the spec is incorrect

##
# Test ticket #7913
{
        my $xmldoc = <<EOXML;
<!DOCTYPE X SYSTEM "example/ext_ent.dtd">
<X>&foo;</X>
EOXML
        my $parser = XML::LibXML->new();

        $parser->load_ext_dtd(1);

        # first time it should work
        my $doc    = $parser->parse_string( $xmldoc );
        is( $doc->documentElement()->string_value(), " test " );

        # lets see if load_ext_dtd(0) works
        $parser->load_ext_dtd(0);
        my $doc2;
        eval {
           $doc2    = $parser->parse_string( $xmldoc );
        };
        isnt($@, '', "error parsing $xmldoc");

        $parser->validation(1);

        $parser->load_ext_dtd(0);
        my $doc3;
        eval {
           $doc3 = $parser->parse_file( "example/article_external_bad.xml" );
        };

        isa_ok( $doc3, 'XML::LibXML::Document');

        $parser->load_ext_dtd(1);
        eval {
           $doc3 = $parser->parse_file( "example/article_external_bad.xml" );
        };

        isnt($@, '', "error parsing example/article_external_bad.xml");
}

{

   my $parser = XML::LibXML->new();

   my $doc = $parser->parse_string('<foo xml:base="foo.xml"/>',"bar.xml");
   my $el = $doc->documentElement;
   is( $doc->URI, "bar.xml" );
   is( $doc->baseURI, "bar.xml" );
   is( $el->baseURI, "foo.xml" );

   $doc->setURI( "baz.xml" );
   is( $doc->URI, "baz.xml" );
   is( $doc->baseURI, "baz.xml" );
   is( $el->baseURI, "foo.xml" );

   $doc->setBaseURI( "bag.xml" );
   is( $doc->URI, "bag.xml" );
   is( $doc->baseURI, "bag.xml" );
   is( $el->baseURI, "foo.xml" );

   $el->setBaseURI( "bam.xml" );
   is( $doc->URI, "bag.xml" );
   is( $doc->baseURI, "bag.xml" );
   is( $el->baseURI, "bam.xml" );

}


{

   my $parser = XML::LibXML->new();

   my $doc = $parser->parse_html_string('<html><head><base href="foo.html"></head><body></body></html>',{ URI => "bar.html" });
   my $el = $doc->documentElement;
   is( $doc->URI, "bar.html" );
   is( $doc->baseURI, "foo.html" );
   is( $el->baseURI, "foo.html" );

   $doc->setURI( "baz.html" );
   is( $doc->URI, "baz.html" );
   is( $doc->baseURI, "foo.html" );
   is( $el->baseURI, "foo.html" );

}

sub tsub {
    my $doc = shift;

    my $th = {};
    $th->{d} = XML::LibXML::Document->createDocument;
    my $e1  = $th->{d}->createElementNS("x","X:foo");

    $th->{d}->setDocumentElement( $e1 );
    my $e2 = $th->{d}->createElementNS( "x","X:bar" );

    $e1->appendChild( $e2 );

    $e2->appendChild( $th->{d}->importNode( $doc->documentElement() ) );

    return $th->{d};
}

sub tsub2 {
    my ($doc,$query)=($_[0],@{$_[1]});
#    return [ $doc->findnodes($query) ];
    return [ $doc->findnodes(encodeToUTF8('iso-8859-1',$query)) ];
}

sub shorten_string { # Used for test naming.
  my $string = shift;
  return "'undef'" if(!defined $string);

  $string =~ s/\n/\\n/msg;
  return $string if(length($string) < 25);
  return $string = substr($string, 0, 10) . "..." . substr($string, -10);
}

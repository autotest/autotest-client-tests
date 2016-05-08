# -*- cperl -*-
# $Id$

##
# these testcases are for xml canonization interfaces.
#

# should be 23.
use Test::More tests => 23;
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::Common qw(:libxml);

my $parser = XML::LibXML->new;

{
    my $doc = $parser->parse_string( "<a><b/> <c/> <!-- d --> </a>" );

    my $c14n_res = $doc->toStringC14N();
    # TEST
    is( $c14n_res, "<a><b></b> <c></c>  </a>", ' TODO : Add test name' );

    $c14n_res = $doc->toStringC14N(1);
    # TEST
    is( $c14n_res, "<a><b></b> <c></c> <!-- d --> </a>", ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( '<a><b/><![CDATA[ >e&f<]]><!-- d --> </a>' );

    my $c14n_res = $doc->toStringC14N();
    # TEST
    is( $c14n_res, '<a><b></b> &gt;e&amp;f&lt; </a>', ' TODO : Add test name' );
    $c14n_res = $doc->toStringC14N(1);
    # TEST
    is( $c14n_res, '<a><b></b> &gt;e&amp;f&lt;<!-- d --> </a>', ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( '<a a="foo"/>' );

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<a a="foo"></a>', ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( '<b:a xmlns:b="http://foo"/>' );

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<b:a xmlns:b="http://foo"></b:a>', ' TODO : Add test name' );
}


# ----------------------------------------------------------------- #
# The C14N says: remove unused namespaces, libxml2 just orders them
# ----------------------------------------------------------------- #
{
    my $doc = $parser->parse_string( '<b:a xmlns:b="http://foo" xmlns:a="xml://bar"/>' );

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<b:a xmlns:a="xml://bar" xmlns:b="http://foo"></b:a>', ' TODO : Add test name' );

    # would be correct, but will not work.
    # ok( $c14n_res, '<b:a xmlns:b="http://foo"></b:a>' );
}

# ----------------------------------------------------------------- #
# The C14N says: remove redundant namespaces
# ----------------------------------------------------------------- #
{
    my $doc = $parser->parse_string( '<b:a xmlns:b="http://foo"><b:b xmlns:b="http://foo"/></b:a>' );

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<b:a xmlns:b="http://foo"><b:b></b:b></b:a>', ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( '<a xmlns="xml://foo"/>' );

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<a xmlns="xml://foo"></a>', ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( <<EOX );
<?xml version="1.0" encoding="iso-8859-1"?>
<a><b/></a>
EOX

    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0);
    # TEST
    is( $c14n_res, '<a><b></b></a>', ' TODO : Add test name' );
}

# canonize with xpath expressions
{
    my $doc = $parser->parse_string( <<EOX );
<?xml version="1.0" encoding="iso-8859-1"?>
<a><b><c/><d/></b></a>
EOX
    my $c14n_res;
    $c14n_res = $doc->toStringC14N(0, "//d" );
    # TEST
    is( $c14n_res, '<d></d>', ' TODO : Add test name' );
}

{
    my $doc = $parser->parse_string( <<EOX );
<?xml version="1.0" encoding="iso-8859-1"?>
<a xmlns="http://foo/test#"><b><c/><d><e/></d></b></a>
EOX
    my $rootnode=$doc->documentElement;
    my $c14n_res;
    $c14n_res = $rootnode->toStringC14N(0, "//*[local-name()='d']");
    # TEST
    is( $c14n_res, '<d></d>', ' TODO : Add test name' );
    ($rootnode) = $doc->findnodes("//*[local-name()='d']");
    $c14n_res = $rootnode->toStringC14N();
    # TEST
    is( $c14n_res, '<d xmlns="http://foo/test#"><e></e></d>', ' TODO : Add test name' );
    $rootnode = $doc->documentElement->firstChild;
    $c14n_res = $rootnode->toStringC14N(0);
    # TEST
    is( $c14n_res, '<b xmlns="http://foo/test#"><c></c><d><e></e></d></b>', ' TODO : Add test name' );
}

# exclusive canonicalization

if (20620 > XML::LibXML::LIBXML_VERSION) {
    skip("skipping Exclusive C14N tests for libxml2 < 2.6.17") for 15..20;
} else {
  my $xml1 = <<EOX;
<n0:local xmlns:n0="http://something.org" xmlns:n3="ftp://example.org">
  <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
     <n3:stuff xmlns:n3="ftp://example.org"/>
  </n1:elem2>
</n0:local>
EOX

  my $xml2 = <<EOX;
<n2:pdu xmlns:n1="http://example.com"
           xmlns:n2="http://foo.example"
           xml:lang="fr"
           xml:space="preserve">
  <n1:elem2 xmlns:n1="http://example.net" xml:lang="en">
     <n3:stuff xmlns:n3="ftp://example.org"/>
  </n1:elem2>
</n2:pdu>
EOX
    my $xpath = "(//. | //@* | //namespace::*)[ancestor-or-self::*[name()='n1:elem2']]";
    my $result = qq(<n1:elem2 xmlns:n1="http://example.net" xml:lang="en">\n     <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>\n  </n1:elem2>);
    my $result_n0n2 = qq(<n1:elem2 xmlns:n1="http://example.net" xmlns:n2="http://foo.example" xml:lang="en">\n     <n3:stuff xmlns:n3="ftp://example.org"></n3:stuff>\n  </n1:elem2>);
  my $doc1 = $parser->parse_string( $xml1 );
  my $doc2 = $parser->parse_string( $xml2 );

  {
    my $c14n_res = $doc1->toStringEC14N(0, $xpath);
    # TEST
    is( $c14n_res, $result, ' TODO : Add test name');
  }
  {
    my $c14n_res = $doc2->toStringEC14N(0, $xpath);
    # TEST
    is( $c14n_res, $result, ' TODO : Add test name');
  }
  {
    my $c14n_res = $doc1->toStringEC14N(0, $xpath,[]);
    # TEST
    is( $c14n_res, $result, ' TODO : Add test name');
  }
  {
    my $c14n_res = $doc2->toStringEC14N(0, $xpath,[]);
    # TEST
    is( $c14n_res, $result, ' TODO : Add test name');
  }
  {
    my $c14n_res = $doc2->toStringEC14N(0, $xpath,['n1','n3']);
    # TEST
    is( $c14n_res, $result, ' TODO : Add test name');
  }
  {
    my $c14n_res = $doc2->toStringEC14N(0, $xpath,['n0','n2']);
    # TEST
    is( $c14n_res, $result_n0n2, ' TODO : Add test name');
  }

}

{

my $xml = <<'EOF';
<?xml version="1.0" encoding="utf-8"?><soapenv:Envelope xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsrl="http://docs.oasis-open.org/wsrf/rl-2" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:Profile="urn:ehealth:profiles:timestamping:1.0" xmlns:tsa="http://www.behealth.be/webservices/tsa" xmlns:urn="urn:oasis:names:tc:dss:1.0:core:schema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsrp="http://docs.oasis-open.org/wsrf/rp-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Header><wsa:Action wsu:Id="Action">http://www.behealth.be/webservices/tsa/TSConsultTSBagRequest</wsa:Action><wsa:To wsu:Id="To">https://www.ehealth.fgov.be/timestampauthority_1_5/timestampauthority</wsa:To><wsa:MessageID wsu:Id="MessageID">urn:www.sve.man.ac.uk-54690551758351720271010843310</wsa:MessageID><wsa:ReplyTo wsu:Id="ReplyTo"><wsa:Address>http://www.w3.org/2005/08/addressing/anonymous</wsa:Address></wsa:ReplyTo></soapenv:Header><soapenv:Body wsu:Id="myBody"><TSConsultTSBagRequest xmlns="http://www.behealth.be/webservices/tsa"><tsa:IDHospital>tsa_0406798006_01</tsa:IDHospital><tsa:TSList><tsa:sequenceNumber>80300231753732</tsa:sequenceNumber><tsa:dateTime>1226995312781</tsa:dateTime></tsa:TSList></TSConsultTSBagRequest></soapenv:Body></soapenv:Envelope>
EOF

my $xpath = q{(//. | //@* | //namespace::*)[ancestor-or-self::x:MessageID]};
my $xpath2 = q{(//. | //@* | //namespace::*)[ancestor-or-self::*[local-name()='MessageID' and namespace-uri()='http://www.w3.org/2005/08/addressing']]};

my $doc = XML::LibXML->load_xml(string=>$xml);
my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs(x => "http://www.w3.org/2005/08/addressing");
my $expect = '<wsa:MessageID xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" wsu:Id="MessageID">urn:www.sve.man.ac.uk-54690551758351720271010843310</wsa:MessageID>';
# TEST

is( $doc->toStringEC14N( 0, $xpath2, [qw(soap)] ), $expect, ' TODO : Add test name' );
# TEST

is( $doc->toStringEC14N( 0, $xpath, $xpc, [qw(soap)] ), $expect, ' TODO : Add test name' );
# TEST

is( $doc->toStringEC14N( 0, $xpath2, $xpc, [qw(soap)] ), $expect, ' TODO : Add test name' );

}

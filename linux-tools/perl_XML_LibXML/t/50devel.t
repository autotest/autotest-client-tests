use Test::More;
BEGIN { plan tests => 18 };

use warnings;
use strict;

BEGIN {$ENV{'DEBUG_MEMORY'} = 1;}
use XML::LibXML;
use XML::LibXML::Devel qw(:all);

$|=1;

# Base line
{
  my $doc = XML::LibXML::Document->new();

  my $raw;
  my $mem_before = mem_used();
  {
    my $node = $doc->createTextNode("Hello");

    $raw = node_from_perl($node);
    refcnt_inc($raw);
  }
  cmp_ok(mem_used(), '>', $mem_before);
  is(refcnt_dec($raw), 1);
  is(mem_used(), $mem_before);

  # Next group of checks - multiple nodes
  my ($rawT, $rawN);
  $mem_before = mem_used();
  {
    my $node = XML::LibXML::Element->new( 'text' );
    my $text = $doc->createTextNode( "Hello" );

    $rawN = node_from_perl($node);
    $rawT = node_from_perl($text);

    refcnt_inc($rawN);
    refcnt_inc($rawT);

    $node->appendChild($text);

    # Done by appendChild
    # fix_owner($rawT, $rawN);
  }
  cmp_ok(mem_used(), '>', $mem_before);
  is(refcnt_dec($rawN), 2);
  is(refcnt_dec($rawT), 1);
  is(mem_used(), $mem_before);

  # The owner node remains until the last node is gone
  my ($rawR, $rawD);
  $mem_before = mem_used();
  {
    my $dom = XML::LibXML->load_xml(string => <<'EOT');
<?xml version="1.0"?>
<test>
  <text>Hello</text>
</test>
EOT
    my ($root) = $dom->getElementsByTagName('test');
    $rawR = node_from_perl($root);
    $rawD = node_from_perl($dom);

    is(refcnt($rawR), 1);
    is(refcnt($rawD), 2);

    my ($node) = $dom->getElementsByTagName('text');
    $rawN = node_from_perl($node);

    is(refcnt($rawN), 1);
    is(refcnt($rawR), 1);
    is(refcnt($rawD), 3);

    refcnt_inc($rawN);

    is(refcnt($rawD), 3);

    my $child = $node->firstChild;

    is(refcnt($rawD), 4);
  }
  cmp_ok(mem_used(), '>', $mem_before);
  # $rawR's proxy node is no longer accessible
  # but $rawD still has one
  is(refcnt($rawD), 1);
  is(refcnt_dec($rawN), 1);
  is(mem_used(), $mem_before);

}



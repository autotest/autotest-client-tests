#!/usr/bin/perl -w
use strict;
use warnings;
use XML::LibXML;
use Test::More tests => 7;

# tests for bug #24953: External entities not expanded in included file (XInclude)

my $parser = XML::LibXML->new;
my $file = 'test/xinclude/test.xml';
{
  $parser->expand_xinclude(0);
  $parser->expand_entities(1);
  # TEST
  ok (scalar ($parser->parse_file($file)->toString() !~  /IT WORKS/), ' TODO : Add test name');
}
{
  $parser->expand_xinclude(1);
  $parser->expand_entities(0);
  # TEST
  ok (scalar($parser->parse_file($file)->toString() !~  /IT WORKS/), ' TODO : Add test name');
}
{
  $parser->expand_xinclude(1);
  $parser->expand_entities(1);
  # TEST
  ok (scalar($parser->parse_file($file)->toString() =~  /IT WORKS/), ' TODO : Add test name');
}
{
  $parser->expand_xinclude(0);
  my $doc = $parser->parse_file($file);
  # TEST
  ok( $doc->process_xinclude({expand_entities=>0}), ' TODO : Add test name' );
  # TEST
  ok( scalar($doc->toString() !~ /IT WORKS/), ' TODO : Add test name' );
}
{
  my $doc = $parser->parse_file($file);
  # TEST
  ok( $doc->process_xinclude({expand_entities=>1}), ' TODO : Add test name' );
  # TEST
  ok( scalar($doc->toString() =~ /IT WORKS/), ' TODO : Add test name' );
}

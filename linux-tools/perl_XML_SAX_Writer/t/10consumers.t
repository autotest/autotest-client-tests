
###
# XML::SAX::Writer tests
# Robin Berjon <robin@knowscape.com>
# 06/01/2002 - v0.01
###

use strict;

package MyConsumer;
@MyConsumer::ISA = qw( XML::SAX::Writer::ConsumerInterface );

sub new {
    my $self = shift->SUPER::new( my $output );
    $$self = '' ;   # Note the extra '$'

    return $self;
}

sub output {
    my $self = shift;
    $$self .= uc shift;
}

sub get_output {
    my $self = shift;
    return $$self;
}


package main;
use Test::More tests => 15;
use XML::SAX::Writer qw();

# StringConsumer
my $ref1 = 'MUST_CLEAR';
my $str = XML::SAX::Writer::StringConsumer->new(\$ref1);
isa_ok($str, 'XML::SAX::Writer::StringConsumer', 'StringConsumer');
$str->output('CONTENT');
my $res1 = $str->finalize;
ok($$res1 eq 'CONTENT', 'content is set');


# ArrayConsumer
my $arr = XML::SAX::Writer::ArrayConsumer->new([]);
isa_ok($arr, 'XML::SAX::Writer::ArrayConsumer', 'ArrayConsumer');
$arr->output('CONTENT0');
$arr->output('CONTENT1');
my $res2 = $arr->finalize;
ok($res2->[0] eq 'CONTENT0', 'content (1)');
ok($res2->[1] eq 'CONTENT1', 'content (2)');


# HandleConsumer and FileConsumer
my $fil1 = XML::SAX::Writer::FileConsumer->new('test_file1');
isa_ok($fil1, 'XML::SAX::Writer::FileConsumer', 'FileConsumer');
isa_ok($fil1, 'XML::SAX::Writer::HandleConsumer', 'HandleConsumer');
$fil1->output('FILE ONE');
my $fil2 = XML::SAX::Writer::FileConsumer->new('test_file2');
$fil2->output('FILE TWO');
$fil1->output(' FILE ONE');
$fil2->output(' FILE TWO');
$fil1->finalize;
$fil2->finalize;

open FH1, "test_file1" or die $!;
my $cnt1 = <FH1>;
close FH1;

open FH2, "test_file2" or die $!;
my $cnt2 = <FH2>;
close FH2;

ok($cnt1 eq 'FILE ONE FILE ONE', 'file content (1)');
ok($cnt2 eq 'FILE TWO FILE TWO', 'file content (2)');


##
## Now, test some of the consumers "in situ"
##

sub push_events {
    my $w = XML::SAX::Writer->new( Output => shift );
    $w->start_document( {} );
    $w->start_element( { Name => "foo" } );
    $w->end_element( { Name => "foo" } );
    $w->end_document( {} );
}

{
    my @events;
    push_events( sub { push @events, [ @_ ] } );
    ok @events >= 3;
    ok $events[0]->[0], "start_document";
    ok $events[1]->[0], "data";
    ok $events[-1]->[0], "end_document";
    ## This next test might break id X::S::W ever stops
    ## putting that space in there.
    ok join( "", map $_->[1], @events ), "<foo />";
}

##
## A custom consumer
##

{
    my $c = MyConsumer->new;
    push_events( $c );
    ok $c->get_output, "<foo />";
}

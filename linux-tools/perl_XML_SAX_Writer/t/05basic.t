
###
# XML::SAX::Writer tests
# Robin Berjon <robin@knowscape.com>
# 06/01/2002 - v0.01
###

use strict;
use Test::More tests => 30;
BEGIN { use_ok('XML::SAX::Writer'); }

# VMS has different names for codepages
my $isoL1 = ($^O eq 'VMS') ? 'iso8859-1' : 'iso-8859-1';
my $isoL2 = ($^O eq 'VMS') ? 'iso8859-2' : 'iso-8859-2';


# default options of XML::SAX::Writer
my $w1 = XML::SAX::Writer->new->{Handler};

ok(        $w1->{EncodeFrom} eq 'utf-8',                       'default EncodeFrom');
ok(        $w1->{EncodeTo}   eq 'utf-8',                       'default EncodeTo');
isa_ok(    $w1->{Output},  'IO::Handle',                       'default Output');
is_deeply( $w1->{Format},  {},                                 'default Format');
is_deeply( $w1->{Escape},  \%XML::SAX::Writer::DEFAULT_ESCAPE, 'default Escape');
is(        $w1->{QuoteCharacter},  q['],                       'default QuoteCharacter');

# set default options of XML::SAX::Writer
my %fmt2 = ( FooBar => 1 );
my $o2 = \'';
my $w2 = XML::SAX::Writer->new({
                                EncodeFrom  => $isoL1,
                                EncodeTo    => $isoL2,
                                Output      => $o2,
                                Format      => \%fmt2,
                                Escape      => {},
                                QuoteCharacter => q["],
                              })->{Handler};
ok(        $w2->{EncodeFrom} eq $isoL1, 'set EncodeFrom');
ok(        $w2->{EncodeTo}   eq $isoL2, 'set EncodeTo');
ok(        "$w2->{Output}"   eq  "$o2",       'set Output');
is_deeply( $w2->{Format},   \%fmt2,           'set Format');
is_deeply( $w2->{Escape},   {},               'set Escape');
is(        $w2->{QuoteCharacter}, q["],       'set QuoteCharacter');

# options after initialisation
$w1->start_document;
isa_ok($w1->{Encoder},  'XML::SAX::Writer::NullConverter', 'null converter for noop encoding');
my $w3 = XML::SAX::Writer->new({
                                EncodeFrom  => $isoL1,
                                EncodeTo    => $isoL2,
                              })->{Handler};
$w3->start_document;
isa_ok($w3->{Encoder},  'XML::SAX::Writer::Encode',        'converter for encoding using Encode');
isa_ok($w1->{NSHelper}, 'XML::NamespaceSupport',           'ns support');
ok(ref($w1->{EscaperRegex}) eq 'Regexp',                    'escaper regex');
ok(ref($w1->{NSDecl})       eq 'ARRAY',                    'ns stack');
ok(@{$w1->{NSDecl}} == 0,                                  'ns stack is clear');
isa_ok($w1->{Consumer}, 'XML::SAX::Writer::ConsumerInterface', 'consumer is set');

# different inits (mostly for Consumer DWIM)
$w1->{EncodeFrom} = $isoL1;
$w1->start_document;

$w1->{Output} = 'test_file_for_output';
$w1->start_document;
isa_ok($w1->{Consumer}, 'XML::SAX::Writer::FileConsumer',   'consumer is FileConsumer');

my $ot = '';
$w1->{Output} = \$ot;
$w1->start_document;
isa_ok($w1->{Consumer}, 'XML::SAX::Writer::StringConsumer', 'consumer is StringConsumer');

$w1->{Output} = [];
$w1->start_document;
isa_ok($w1->{Consumer}, 'XML::SAX::Writer::ArrayConsumer',  'consumer is ArrayConsumer');

$w1->{Output} = *STDOUT;
$w1->start_document;
isa_ok($w1->{Consumer}, 'XML::SAX::Writer::HandleConsumer', 'consumer is HandleConsumer');

$w1->{Output} = bless [], 'Test__XSW1';
sub Test__XSW1::output {}
$w1->start_document;
isa_ok($w1->{Consumer}, 'Test__XSW1',                       'consumer is custom');

$w1->{Output} = bless [], 'Test__XSW2';
eval { $w1->start_document; };
ok($@, 'bad consumer');
isa_ok($@, 'XML::SAX::Writer::Exception', 'bad consumer exception');

# escaping
my $esc1 = '<>&"\'';
my $eq1  = '&lt;&gt;&amp;&quot;&apos;';
my $res1 = $w1->escape($esc1);
is($res1, $eq1, 'escaping (default)');

# converting
my $conv1 = XML::SAX::Writer::NullConverter->new;
my $str1 = 'TEST';
my $res_1 = $conv1->convert($str1);
is($str1, $res_1, 'noop converter');

my $conv2 = XML::SAX::Writer::Encode->new('iso-8859-1', 'utf-8');
my $str2 = 'Cönvert';
my $res_2 = $conv2->convert($str2);
use Encode;
Encode::from_to($str2, 'iso-8859-1', 'utf-8');
is($str2, $res_2, 'Encode converter');

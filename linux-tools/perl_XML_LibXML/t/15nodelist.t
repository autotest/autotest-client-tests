
use strict;
use warnings;

use Test::More tests => 27;

use XML::LibXML;
use IO::Handle;

# TEST
ok(1, ' TODO : Add test name');

my $dom = XML::LibXML->new->parse_fh(*DATA);

# TEST
ok($dom, ' TODO : Add test name');

{
	my $nodelist = $dom->documentElement->childNodes;
    # TEST
	# 0 is #text
	is ($nodelist->item(1)->nodeName, 'BBB', 'item is 0-indexed');
}

my @nodelist = $dom->findnodes('//BBB');

# TEST
is(scalar(@nodelist), 5, ' TODO : Add test name');

my $nodelist = $dom->findnodes('//BBB');
# TEST
is($nodelist->size, 5, ' TODO : Add test name');

# TEST
is($nodelist->string_value, "OK", ' TODO : Add test name'); # first node in set

# TEST
is($nodelist->to_literal, "OKNOT OK", ' TODO : Add test name');

{
    my $other_nodelist = $dom->findnodes('//BBB');
    while ($other_nodelist->to_literal() !~ m/\ANOT OK/)
    {
        $other_nodelist->shift();
    }

    # This is a test for:
    # https://rt.cpan.org/Ticket/Display.html?id=57737

    # TEST
    ok (scalar(($other_nodelist) lt ($nodelist)), "Comparison is OK.");

    # TEST
    ok (scalar(($nodelist) gt ($other_nodelist)), "Comparison is OK.");
}

# TEST
is($dom->findvalue("//BBB"), "OKNOT OK", ' TODO : Add test name');

# TEST
is(ref($dom->find("1 and 2")), "XML::LibXML::Boolean", ' TODO : Add test name');

# TEST
is(ref($dom->find("'Hello World'")), "XML::LibXML::Literal", ' TODO : Add test name');

# TEST
is(ref($dom->find("32 + 13")), "XML::LibXML::Number", ' TODO : Add test name');

# TEST
is(ref($dom->find("//CCC")), "XML::LibXML::NodeList", ' TODO : Add test name');

my $numbers = XML::LibXML::NodeList->new(1..10);
my $oddify  = sub { $_ + ($_%2?0:9) }; # add 9 to even numbers
my @map = $numbers->map($oddify);

# TEST
is(scalar(@map), 10, 'map called in list context returns list');

# TEST
is(join('|',@map), '1|11|3|13|5|15|7|17|9|19', 'mapped data correct');

my $map = $numbers->map($oddify);

# TEST
isa_ok($map => 'XML::LibXML::NodeList', '$map');

my @map2 = $map->map(sub { $_ > 10 ? () : ($_,$_,$_) });

# TEST
is(join('|',@map2), '1|1|1|3|3|3|5|5|5|7|7|7|9|9|9', 'mapping can add/remove nodes');

my @grep = $numbers->grep(sub {$_%2});
my $grep = $numbers->grep(sub {$_%2});

# TEST
is(join('|',@grep), '1|3|5|7|9', 'grep works');

# TEST
isa_ok($grep => 'XML::LibXML::NodeList', '$grep');

my $shuffled = XML::LibXML::NodeList->new(qw/1 4 2 3 6 5 9 7 8 10/);
my @alphabetical = $shuffled->sort(sub { my ($a, $b) = @_; $a cmp $b });
my @numeric      = $shuffled->sort(sub { my ($a, $b) = @_; $a <=> $b });

# TEST
is(join('|',@alphabetical), '1|10|2|3|4|5|6|7|8|9', 'sort works 1');

# TEST
is(join('|',@numeric), '1|2|3|4|5|6|7|8|9|10', 'sort works 2');

my $reverse = XML::LibXML::NodeList->new;
my $return  = $numbers->foreach( sub { $reverse->unshift($_) } );

# TEST
is(
  blessed_refaddr($return),
  blessed_refaddr($numbers),
  'foreach returns $self',
  );

# TEST
is(join('|',@$reverse), '10|9|8|7|6|5|4|3|2|1', 'foreach works');

my $biggest  = $shuffled->reduce(sub { $_[0] > $_[1] ? $_[0] : $_[1] }, -1);
my $smallest = $shuffled->reduce(sub { $_[0] < $_[1] ? $_[0] : $_[1] }, 9999);

# TEST
is($biggest, 10, 'reduce works 1');

# TEST
is($smallest, 1, 'reduce works 2');

my @reverse = $numbers->reverse;

# TEST
is(join('|',@reverse), '10|9|8|7|6|5|4|3|2|1', 'reverse works');

# modified version of Scalar::Util::PP::refaddr
# only works with blessed references
sub blessed_refaddr {
  return undef unless length(ref($_[0]));
  my $addr;
  if(defined(my $pkg = ref($_[0]))) {
    $addr .= bless $_[0], 'Scalar::Util::Fake';
    bless $_[0], $pkg;
  }
  $addr =~ /0x(\w+)/;
  local $^W;
  hex($1);
}


__DATA__
<AAA>
<BBB>OK</BBB>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB>NOT OK</BBB></DDD></CCC>
</AAA>

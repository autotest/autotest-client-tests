BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::XQL;
use XML::XQL::DOM;
use XML::XQL::Debug;
$loaded = 1;
print "ok 1\n";

my $test = 1;
sub assert_ok
{
    my $ok = shift;
    print "not " unless $ok;
    ++$test;
    print "ok $test\n";
    $ok;
}

sub assert_output
{
    my $str = shift;
    $^W=0;
    my $data = join('',<DATA>);
#print "{{$data}}\n{{$str}}\n";
    assert_ok ($str eq $data);
}
#Test 2

$dom = new XML::DOM::Parser;

my $doc = $dom->parsefile (XML::XQL::Debug::filename("samples/bookstore.xml"));
assert_ok ($doc); 

@result = XML::XQL::solve ('//book/(@style | title | price | price/@exchange | price/@intl)', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Attr'>
style="autobiography"
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<title>Seven Years in Trenton</title>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<price>12</price>
    </obj>
  </item>
  <item index='3'>
    <obj type='XML::DOM::Attr'>
style="textbook"
    </obj>
  </item>
  <item index='4'>
    <obj type='XML::DOM::Element'>
<title>History of Trenton</title>
    </obj>
  </item>
  <item index='5'>
    <obj type='XML::DOM::Element'>
<price>55</price>
    </obj>
  </item>
  <item index='6'>
    <obj type='XML::DOM::Attr'>
style="novel"
    </obj>
  </item>
  <item index='7'>
    <obj type='XML::DOM::Element'>
<title>Trenton Today, Trenton Tomorrow</title>
    </obj>
  </item>
  <item index='8'>
    <obj type='XML::DOM::Element'>
<price intl="canada" exchange="0.7">6.50</price>
    </obj>
  </item>
  <item index='9'>
    <obj type='XML::DOM::Attr'>
intl="canada"
    </obj>
  </item>
  <item index='10'>
    <obj type='XML::DOM::Attr'>
exchange="0.7"
    </obj>
  </item>
</array>

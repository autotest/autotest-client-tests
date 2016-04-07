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
my $str = <<END;
<library>
 <book>book 1</book>
 <magazine>mag 1</magazine>
 <book>book 2</book>
 <book>book 3</book>
 <magazine>mag 2</magazine>
 <book>book 4</book>
 <magazine>mag 3</magazine>
 <magazine>mag 4</magazine>
 <book>book 5</book>
</library>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('library/book[index() < 4]', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<book>book 1</book>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<book>book 2</book>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<book>book 3</book>
    </obj>
  </item>
  <item index='3'>
    <obj type='XML::DOM::Element'>
<book>book 4</book>
    </obj>
  </item>
</array>

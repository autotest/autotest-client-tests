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
<x>
  <q>
    <y id="A"/>
    <y id="B"/>
  </q>
  <q>
    <y id="C"/>
    <y id="D"/>
  </q>
  <y id="E"/>
</x>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('x//y[0]', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<y id="A"/>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<y id="C"/>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<y id="E"/>
    </obj>
  </item>
</array>

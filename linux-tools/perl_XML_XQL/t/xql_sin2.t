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
<DATA>
 <VAL>1</VAL>
 <VAL>2</VAL>
 <VAL>3</VAL>
 <VAL>4</VAL>
</DATA>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('sin(DATA/*)', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::XQL::Number'>0.841470984807897</obj>
  </item>
  <item index='1'>
    <obj type='XML::XQL::Number'>0.909297426825682</obj>
  </item>
  <item index='2'>
    <obj type='XML::XQL::Number'>0.141120008059867</obj>
  </item>
  <item index='3'>
    <obj type='XML::XQL::Number'>-0.756802495307928</obj>
  </item>
</array>

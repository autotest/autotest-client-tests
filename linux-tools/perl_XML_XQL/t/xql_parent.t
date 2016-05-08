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
<doc>
 <a>
  <b val="1">
   <c attr="foo">c1</c>
  </b>
 </a>
 <a>
  <b val = "2">
   <c attr="foo">c2</c>
  </b>
 </a>
</doc>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('doc/a/b/c[@attr="foo"]/..', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<b val="1">
   <c attr="foo">c1</c>
  </b>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<b val="2">
   <c attr="foo">c2</c>
  </b>
    </obj>
  </item>
</array>

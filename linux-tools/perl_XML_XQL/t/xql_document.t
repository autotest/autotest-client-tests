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
 <file name="t/attr2.xml"/>
 <file name="t/attr3.xml"/>
</doc>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('document (doc/file/@name)/root', $doc);
$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<root>
 <abc><a/><b/><c/><a/></abc>
 <c01/>
 <c01><c/></c01>
 <c01><c/><c/></c01>
</root>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<root>
 <a attr="uses gen_ent">Entity ref gen_ent in text</a>
</root>
    </obj>
  </item>
</array>

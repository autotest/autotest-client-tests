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
 <foo index='0'/>
 <foo index='1'/>
 <foo index='2'/>
 <foo index='3'/>
 <foo index='4'/>
 <foo index='5'/>
 <foo index='6'/>
 <foo index='7'/>
 <foo index='8'/>
 <foo index='9'/>
</doc>
END

my $doc = $dom->parse ($str);
assert_ok ($doc);

@result = XML::XQL::solve ('doc/foo[1, 3 to 5, -4, -2 to -1]', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<foo index="1"/>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<foo index="3"/>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<foo index="4"/>
    </obj>
  </item>
  <item index='3'>
    <obj type='XML::DOM::Element'>
<foo index="5"/>
    </obj>
  </item>
  <item index='4'>
    <obj type='XML::DOM::Element'>
<foo index="6"/>
    </obj>
  </item>
  <item index='5'>
    <obj type='XML::DOM::Element'>
<foo index="8"/>
    </obj>
  </item>
  <item index='6'>
    <obj type='XML::DOM::Element'>
<foo index="9"/>
    </obj>
  </item>
</array>

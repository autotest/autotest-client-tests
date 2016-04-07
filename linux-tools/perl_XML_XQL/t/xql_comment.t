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
<DATE>1993-02-14</DATE>
<!-- comment 1 -->
<!-- comment 2 -->
<CKL cklAttr="cklAttrVal1">
<CKLID>P001</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<!-- comment 3 -->
<ADDRESS>HNLLHIWP</ADDRESS>
</LOCALCONTACT>
</CKL>
<CKL cklAttr="cklAttrVal2">
<CKLID>0002</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<ADDRESS>45 HOLOMOA STREET</ADDRESS>
<!-- comment 4 -->
<!-- comment 5 -->
</LOCALCONTACT>
</CKL>
<!-- comment 6 -->
</DATA>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('//comment()', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Comment'>
<!-- comment 1 -->
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Comment'>
<!-- comment 2 -->
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Comment'>
<!-- comment 3 -->
    </obj>
  </item>
  <item index='3'>
    <obj type='XML::DOM::Comment'>
<!-- comment 4 -->
    </obj>
  </item>
  <item index='4'>
    <obj type='XML::DOM::Comment'>
<!-- comment 5 -->
    </obj>
  </item>
  <item index='5'>
    <obj type='XML::DOM::Comment'>
<!-- comment 6 -->
    </obj>
  </item>
</array>

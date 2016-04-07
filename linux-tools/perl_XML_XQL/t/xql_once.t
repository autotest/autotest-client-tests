BEGIN {print "1..5\n";}
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
<COS>1</COS>
<CKL cklAttr="cklAttrVal1">
<CKLID>P001</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<ADDRESS>HNLLHIWP</ADDRESS>
</LOCALCONTACT>
</CKL>
<CKL cklAttr="cklAttrVal2">
<CKLID>0002</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<ADDRESS>45 HOLOMOA STREET</ADDRESS>
</LOCALCONTACT>
</CKL>
</DATA>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

my $counter = 0;
sub incr_counter
{
    my ($context, $list, $expr) = @_;
    $counter++;
    $expr->solve ($context, $list);
}

XML::XQL::defineFunction ("incr", \&incr_counter, 1, 1, 0);

# incr is evaluated 4 times
@result = XML::XQL::solve ('DATA/*[. = incr(cos(0))]', $doc);
assert_ok ($counter == 4);
$counter = 0;

# incr is evaluated only once
@result = XML::XQL::solve ('DATA/*[. = once(incr(cos(0)))]', $doc);
assert_ok ($counter == 1);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<COS>1</COS>
    </obj>
  </item>
</array>

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
<TABLE>
 <ROWS>
  <TR>
   <TD>Shady Grove</TD>
   <TD>Aeolian</TD>
  </TR>
  <TR>
   <TD>Over the River, Charlie</TD>
   <TD>Dorian</TD>
  </TR>
 </ROWS>
</TABLE>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('//(TD="Shady Grove" ; TD)', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<TD>Shady Grove</TD>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<TD>Aeolian</TD>
    </obj>
  </item>
</array>

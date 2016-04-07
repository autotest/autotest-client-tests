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
<SPEECH>
 <SPEAKER>MARCELLUS</SPEAKER>
 <LINE>Tis gone!</LINE>
 <STAGEDIR>Exit Ghost</STAGEDIR>
 <LINE>We do it wrong, being so majestical,</LINE>
 <LINE>To offer it the show of violence;</LINE>
 <LINE>For it is, as the air, invulnerable,</LINE>
 <LINE>And our vain blows malicious mockery.</LINE>
</SPEECH>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

#@result = XML::XQL::solve ('SPEECH//(SPEAKER ;; LINE)', $doc);
@result = XML::XQL::solve ('SPEECH//(SPEAKER ;; LINE ; STAGEDIR = "Exit Ghost")', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<SPEAKER>MARCELLUS</SPEAKER>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<LINE>Tis gone!</LINE>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<STAGEDIR>Exit Ghost</STAGEDIR>
    </obj>
  </item>
</array>

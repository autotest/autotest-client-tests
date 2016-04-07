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
my $doc = $dom->parsefile (XML::XQL::Debug::filename("samples/REC-xml-19980210.xml"));
assert_ok ($doc); 

@result = XML::XQL::solve ('//p[termdef =~ "/entit/"]//prod', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
assert_output ($result);

__DATA__
<array>
  <item index='0'>
    <obj type='XML::DOM::Element'>
<prod id="NT-Char"><lhs>Char</lhs> 
<rhs>#x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] 
| [#x10000-#x10FFFF]</rhs> 
<com>any Unicode character, excluding the
surrogate blocks, FFFE, and FFFF.</com> </prod>
    </obj>
  </item>
  <item index='1'>
    <obj type='XML::DOM::Element'>
<prod id="NT-EntityDecl"><lhs>EntityDecl</lhs>
<rhs><nt def="NT-GEDecl">GEDecl</nt><!--</rhs><com>General entities</com>
<rhs>--> | <nt def="NT-PEDecl">PEDecl</nt></rhs>
<!--<com>Parameter entities</com>-->
</prod>
    </obj>
  </item>
  <item index='2'>
    <obj type='XML::DOM::Element'>
<prod id="NT-GEDecl"><lhs>GEDecl</lhs>
<rhs>'&lt;!ENTITY' <nt def="NT-S">S</nt> <nt def="NT-Name">Name</nt> 
<nt def="NT-S">S</nt> <nt def="NT-EntityDef">EntityDef</nt> 
<nt def="NT-S">S</nt>? '&gt;'</rhs>
</prod>
    </obj>
  </item>
  <item index='3'>
    <obj type='XML::DOM::Element'>
<prod id="NT-PEDecl"><lhs>PEDecl</lhs>
<rhs>'&lt;!ENTITY' <nt def="NT-S">S</nt> '%' <nt def="NT-S">S</nt> 
<nt def="NT-Name">Name</nt> <nt def="NT-S">S</nt> 
<nt def="NT-PEDef">PEDef</nt> <nt def="NT-S">S</nt>? '&gt;'</rhs>
<!--<com>Parameter entities</com>-->
</prod>
    </obj>
  </item>
  <item index='4'>
    <obj type='XML::DOM::Element'>
<prod id="NT-EntityDef"><lhs>EntityDef</lhs>
<rhs><nt def="NT-EntityValue">EntityValue</nt>
<!--</rhs>
<rhs>-->| (<nt def="NT-ExternalID">ExternalID</nt> 
<nt def="NT-NDataDecl">NDataDecl</nt>?)</rhs>
<!-- <nt def='NT-ExternalDef'>ExternalDef</nt></rhs> -->
</prod>
    </obj>
  </item>
  <item index='5'>
    <obj type='XML::DOM::Element'>
<prod id="NT-PEDef"><lhs>PEDef</lhs>
<rhs><nt def="NT-EntityValue">EntityValue</nt> 
| <nt def="NT-ExternalID">ExternalID</nt></rhs></prod>
    </obj>
  </item>
  <item index='6'>
    <obj type='XML::DOM::Element'>
<prod id="NT-ExternalID"><lhs>ExternalID</lhs>
<rhs>'SYSTEM' <nt def="NT-S">S</nt> 
<nt def="NT-SystemLiteral">SystemLiteral</nt></rhs>
<rhs>| 'PUBLIC' <nt def="NT-S">S</nt> 
<nt def="NT-PubidLiteral">PubidLiteral</nt> 
<nt def="NT-S">S</nt> 
<nt def="NT-SystemLiteral">SystemLiteral</nt>
</rhs>
</prod>
    </obj>
  </item>
  <item index='7'>
    <obj type='XML::DOM::Element'>
<prod id="NT-NDataDecl"><lhs>NDataDecl</lhs>
<rhs><nt def="NT-S">S</nt> 'NDATA' <nt def="NT-S">S</nt> 
<nt def="NT-Name">Name</nt></rhs>
<vc def="not-declared"/></prod>
    </obj>
  </item>
  <item index='8'>
    <obj type='XML::DOM::Element'>
<prod id="NT-NotationDecl"><lhs>NotationDecl</lhs>
<rhs>'&lt;!NOTATION' <nt def="NT-S">S</nt> <nt def="NT-Name">Name</nt> 
<nt def="NT-S">S</nt> 
(<nt def="NT-ExternalID">ExternalID</nt> | 
<nt def="NT-PublicID">PublicID</nt>)
<nt def="NT-S">S</nt>? '&gt;'</rhs></prod>
    </obj>
  </item>
  <item index='9'>
    <obj type='XML::DOM::Element'>
<prod id="NT-PublicID"><lhs>PublicID</lhs>
<rhs>'PUBLIC' <nt def="NT-S">S</nt> 
<nt def="NT-PubidLiteral">PubidLiteral</nt> 
</rhs></prod>
    </obj>
  </item>
</array>

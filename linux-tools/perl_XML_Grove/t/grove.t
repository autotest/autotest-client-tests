# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Grove;
use XML::Parser::PerlSAX;
use XML::Grove::Builder;
use XML::Grove::AsString;
use XML::Grove::AsCanonXML;
use utf8;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# TEST: grove building
$grove_builder = XML::Grove::Builder->new;
$p = new XML::Parser::PerlSAX Handler => $grove_builder;
$g = $p->parse (<<'EOF');
<!DOCTYPE bible [
 <!-- 
  These are unicode character references corresponding to the
  rather idiosyncratic phonetic markup in this particular printing.
  Note that some of the references include the character and
  diacritic, for others you have things like a&dotabove; to
  get a dotted-a.
 -->
 <!ENTITY Amacron  "&#x100;">
 <!ENTITY abreve   "&#x103;">
 <!ENTITY prime    "&#x2b9;">
 <!ENTITY ebreve   "&#x115;">
 <!ENTITY uptack   "&#x2d4;">
 <!ENTITY imacron  "&#x12b;">
 <!ENTITY emacron  "&#x113;">
 <!ENTITY dotabove "&#x307;">
 <!ENTITY umacron  "&#x16b;">
 <!ENTITY ParaMark "&#x0b6;">
 
 <!ENTITY Ahab      "&Amacron;&prime;h&abreve;b">
 <!ENTITY Jezebel   "J&ebreve;z&prime;e-b&ebreve;l">
 <!ENTITY Elijah    "E&uptack;-l&imacron;&prime;jah">
 <!ENTITY Beersheba "B&emacron;&prime;er-sh&emacron;&prime;ba&dotabove;">
 <!ENTITY Judah     "J&umacron;&prime;dah">
 <!ENTITY God       "L<smallcaps>ORD</smallcaps>">
]>
<bible>
<testament><title>The Old Testament</title>
...
<book id="OneKings"> <!-- ID's in XML can't begin with numbers -->
<title>The First Book of the Kings</title>
<subtitle>Commonly called The Third Book of the Kings</subtitle>
...
<chapter 
 num='19'>
<narrative>Jezebel threatens Elijah</narrative>
<verse dotted='true' num='1'>And &Ahab; told &Jezebel;
all that &Elijah; had done, and withal how he had slain all the prophets with
the sword.
<xref c='18' v='40'/></verse>
<verse dotted='true' num='2'>Then &Jezebel; sent a messenger unto &Elijah;,
saying, So let the gods do <i>to me</i>, and more also, if I make not thy life
as the life of one of them by to morrow about this time.
<xref b='Ru' c='1' v='17'/>
<xref c='2' v='23'/>
<xref n='Pr' c='27' v='1'/>
</verse>
<verse dotted='false' num='3'>And when he saw <i>that</i>, he arose, and went
for his life, and came to &Beersheba;, which <i>belongeth</i> to
&Judah;, and left his servant there.</verse>
<verse dotted='true' num='4'>&ParaMark; But he himself went a day's journey
into the wilderness, and came and sat down under a juniper tree: and he
requested for himself that he might die; and said, It is enough; now, O &God;,
take away my life; for I <i>am</i> not better than my fathers.
<xref b='Nu' c='11' v='15'/>
<xref b='Jon' c='4' v='3,8'/>
<xref b='Ph' c='1' v='21-24'/>
<footnote>for himself, or for his life</footnote>
</verse>
<narrative>An angel ministers to him</narrative>
<verse dotted='true' num='5'>And as he lay and slept under a juniper tree,
behold, then an angel touched him, and said unto him, Arise <i>and</i> eat.
<xref b='Ps' c='34' v='7'/>
<xref b='Ac' c='12' v='7'/>
<xref b='Heb' c='1' v='14'/>
</verse>
...
</chapter>
...
</book>
...
</testament>
...
</bible>
EOF
print "ok 2\n";

# TEST: as_cannon_xml
$expected = <<'EOF';
<bible>&#10;<testament><title>The Old Testament</title>&#10;...&#10;<book id="OneKings"> &#10;<title>The First Book of the Kings</title>&#10;<subtitle>Commonly called The Third Book of the Kings</subtitle>&#10;...&#10;<chapter num="19">&#10;<narrative>Jezebel threatens Elijah</narrative>&#10;<verse dotted="true" num="1">And Āʹhăb told Jĕzʹe-bĕl&#10;all that E˔-līʹjah had done, and withal how he had slain all the prophets with&#10;the sword.&#10;<xref c="18" v="40"></xref></verse>&#10;<verse dotted="true" num="2">Then Jĕzʹe-bĕl sent a messenger unto E˔-līʹjah,&#10;saying, So let the gods do <i>to me</i>, and more also, if I make not thy life&#10;as the life of one of them by to morrow about this time.&#10;<xref b="Ru" c="1" v="17"></xref>&#10;<xref c="2" v="23"></xref>&#10;<xref c="27" n="Pr" v="1"></xref>&#10;</verse>&#10;<verse dotted="false" num="3">And when he saw <i>that</i>, he arose, and went&#10;for his life, and came to Bēʹer-shēʹbȧ, which <i>belongeth</i> to&#10;Jūʹdah, and left his servant there.</verse>&#10;<verse dotted="true" num="4">¶ But he himself went a day's journey&#10;into the wilderness, and came and sat down under a juniper tree: and he&#10;requested for himself that he might die; and said, It is enough; now, O L<smallcaps>ORD</smallcaps>,&#10;take away my life; for I <i>am</i> not better than my fathers.&#10;<xref b="Nu" c="11" v="15"></xref>&#10;<xref b="Jon" c="4" v="3,8"></xref>&#10;<xref b="Ph" c="1" v="21-24"></xref>&#10;<footnote>for himself, or for his life</footnote>&#10;</verse>&#10;<narrative>An angel ministers to him</narrative>&#10;<verse dotted="true" num="5">And as he lay and slept under a juniper tree,&#10;behold, then an angel touched him, and said unto him, Arise <i>and</i> eat.&#10;<xref b="Ps" c="34" v="7"></xref>&#10;<xref b="Ac" c="12" v="7"></xref>&#10;<xref b="Heb" c="1" v="14"></xref>&#10;</verse>&#10;...&#10;</chapter>&#10;...&#10;</book>&#10;...&#10;</testament>&#10;...&#10;</bible>
EOF
chop ($expected);
$got = $g->as_canon_xml;

print (($got eq $expected) ? "ok 3\n" : "not ok 3\n");

# TEST: as_string
$expected = <<'EOF';

The Old Testament
...
 
The First Book of the Kings
Commonly called The Third Book of the Kings
...

Jezebel threatens Elijah
And Āʹhăb told Jĕzʹe-bĕl
all that E˔-līʹjah had done, and withal how he had slain all the prophets with
the sword.

Then Jĕzʹe-bĕl sent a messenger unto E˔-līʹjah,
saying, So let the gods do to me, and more also, if I make not thy life
as the life of one of them by to morrow about this time.




And when he saw that, he arose, and went
for his life, and came to Bēʹer-shēʹbȧ, which belongeth to
Jūʹdah, and left his servant there.
¶ But he himself went a day's journey
into the wilderness, and came and sat down under a juniper tree: and he
requested for himself that he might die; and said, It is enough; now, O LORD,
take away my life; for I am not better than my fathers.



for himself, or for his life

An angel ministers to him
And as he lay and slept under a juniper tree,
behold, then an angel touched him, and said unto him, Arise and eat.




...

...

...

...
EOF

$got = $g->as_string;

print (($got eq $expected) ? "ok 4\n" : "not ok 4\n");

# TEST: attr_as_string
$got = $g->root->{Contents}[1]{Contents}[4]->attr_as_string ('id');
print (($got eq 'OneKings') ? "ok 5\n" : "not ok 5\n");

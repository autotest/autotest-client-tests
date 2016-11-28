require Font::AFM;

eval {
   $font = Font::AFM->new("phvr-o");
};
if ($@) {
   if ($@ =~ /Can't find the AFM file for/) {
	print "1..0 # Skipped: Can't find required font\n";
	print "# $@";
   } else {
	print "1..1\n";
        print "# $@";
	print "not ok 1 Found font OK\n";
   }
   exit;
}
print "1..1\n";

$sw = $font->stringwidth("Gisle Aas");

if ($sw == 4279) {
    print "ok 1 Stringwith for phvr seems to work\n";
} else {
    print "not ok 1 The stringwidth of 'Gisle Aas' should be 4279 (it was $sw)\n";
}

$sw = $font->FullName;

if ($sw == "Helvetica-Ogonki Composite font") {
    print "ok 1 FullName for phvr seems to work\n";
} else {
    print "not ok 1 The FullName  should be Helvetica-Ogonki Composite font (it was $sw)\n";
}

$sw = $font->FontBBox;

if ($sw == "-174 -220 1001 944") {
    print "ok 1 FontBox for phvr seems to work\n";
} else {
    print "not ok 1 The FontBox  should be -174 -220 1001 944 (it was $sw)\n";
}

#print "FontBBox = $sw\n";

$sw = $font->EncodingScheme;

if ($sw == "StandardEncoding") {
    print "ok 1 EncodingScheme for phvr seems to work\n";
} else {
    print "not ok 1 The EncodingScheme  should be StandardEncoding (it was $sw)\n";
}

#print "StandardEncoding = $sw\n";

$sw = $font->FontName;

if ($sw == "Helvetica-Ogonki") {
    print "ok 1 FontName for phvr seems to work\n";
} else {
    print "not ok 1 The FontName  should be Helvetica-Ogonki (it was $sw)\n";
}

#print "FontName $sw\n";

#$sw = $font->UnderlineThickness;
#print "UnderlineThickness= $sw\n";



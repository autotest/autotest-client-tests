# Hey Emacs, this is -*- perl -*- !
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: canon_xml_writer.t,v 1.2 1999/08/10 21:42:39 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::PerlSAX;
use XML::Handler::CanonXMLWriter;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $parser = XML::Parser::PerlSAX->new;

my $writer = XML::Handler::CanonXMLWriter->new;
if ($writer) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
    exit;
}


#
# The following XML is copied from XML::Parser by Clark Cooper
#

# XML string for tests

my $xmlstring =<<"End_of_XML;";
<!DOCTYPE foo
  [
    <!NOTATION bar PUBLIC "qrs">
    <!ENTITY zinger PUBLIC "xyz" "abc" NDATA bar>
   ]>
<foo>
  First line in foo
  <bar id="jack" stomp="jill">
  <?line-noise *&*&^&<< ?>
    1st line in bar
    <blah> 2nd line in bar </blah>
    3rd line in bar <!-- Isn't this a doozy -->
  </bar>
  <zap ref="zing" />
</foo>
End_of_XML;

###
### plain test
###

$expected_result = <<'End_of_XML;';
<foo>&#10;  First line in foo&#10;  <bar id="jack" stomp="jill">&#10;  <?line-noise *&*&^&<< ?>&#10;    1st line in bar&#10;    <blah> 2nd line in bar </blah>&#10;    3rd line in bar &#10;  </bar>&#10;  <zap ref="zing"></zap>&#10;</foo>
End_of_XML;
$expected_result =~ s/\n$//s;

$canon_xml = $parser->parse( Source => { String => $xmlstring },
                             Handler => $writer );

if ($canon_xml eq $expected_result) {
    print "ok 3\n";
} else {
    warn "---- expected result ----\n";
    warn "$expected_result\n";
    warn "---- actual result ----\n";
    warn "$canon_xml\n";
    print "not ok 3\n";
}

###
### Test PrintComments option
###

$expected_result = <<'End_of_XML;';
<foo>&#10;  First line in foo&#10;  <bar id="jack" stomp="jill">&#10;  <?line-noise *&*&^&<< ?>&#10;    1st line in bar&#10;    <blah> 2nd line in bar </blah>&#10;    3rd line in bar <!-- Isn't this a doozy -->&#10;  </bar>&#10;  <zap ref="zing"></zap>&#10;</foo>
End_of_XML;
$expected_result =~ s/\n$//s;

$writer->{PrintComments} = 1;
$canon_xml = $parser->parse( Source => { String => $xmlstring },
                             Handler => $writer );

if ($canon_xml eq $expected_result) {
    print "ok 4\n";
} else {
    warn "---- expected result ----\n";
    warn "$expected_result\n";
    warn "---- actual result ----\n";
    warn "$canon_xml\n";
    print "not ok 4\n";
}

undef $writer->{PrintComments};

###
### Test James Clark's XML test suite
###

$xml_test = (defined $ENV{XMLTEST}) ? $ENV{XMLTEST} : "$ENV{HOME}/xmltest";

# allow test to skip if directory does not exist and MUST_TEST isn't set
if (!-d $xml_test && !defined($ENV{MUST_TEST})) {
    print "ok 5\n";
    exit;
}

$tested_file = 0;
foreach $file (glob("$xml_test/valid/sa/*.xml")) {
    $tested_file = 1;
    $canon_xml = $parser->parse( Source => { SystemId => $file },
				 Handler => $writer );
    # add the `out' dir to get the corresponding canon xml
    ($out_file = $file) =~ s|/([^/]+)$|/out/$1|;
    open (CANON, $out_file)
	or die "$out_file: $!\n";
    $expected_result = join('', <CANON>);
    close (CANON);
    if ($canon_xml ne $expected_result) {
	warn "---- expected result for $file ----\n";
	warn "$expected_result\n";
	warn "---- actual result ----\n";
	warn "$canon_xml\n";
	$not_ok = 1;
    }
}

if (!$tested_file || $not_ok) {
    print "not ok 5\n";
} else {
    print "ok 5\n";
}

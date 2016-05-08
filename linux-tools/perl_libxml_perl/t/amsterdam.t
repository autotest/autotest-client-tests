# Hey Emacs, this is -*- perl -*- !
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: amsterdam.t,v 1.1 1999/08/28 17:46:57 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::PerlSAX;
use XML::PatAct::MatchName;
use XML::PatAct::Amsterdam;


$loaded = 1;
print "ok 1\n";

$patterns =
    [
     'outer' => { Before => "Outer-before, '[attr]'",
		  After => "Outer-after\n" },
     'inner' => { Before => "Inner" },
     ];
     
my $matcher = XML::PatAct::MatchName->new( Patterns => $patterns );
my $handler = XML::PatAct::Amsterdam->new( Patterns => $patterns,
					   Matcher => $matcher,
					   AsString => 1 );
my $parser = XML::Parser::PerlSAX->new( Handler => $handler );
$string = $parser->parse(Source => { String => <<'EOF;' } );
<outer attr='an attr'>
  <inner/>
</outer>
EOF;

$expected = <<"EOF;";
Outer-before, 'an attr'
  Inner
Outer-after
EOF;

print (($string eq $expected) ? "ok 2\n" : "not ok 2\n");

# Hey Emacs, this is -*- perl -*- !
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: stream.t,v 1.2 2003/10/21 16:01:54 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::PerlSAX;
use XML::Handler::XMLWriter;


$loaded = 1;
print "ok 1\n";

my $subs = MySubs->new( AsString => 1 );
my $parser = XML::Parser::PerlSAX->new( Handler => $subs );
$string = $parser->parse(Source => { Encoding => 'ISO-8859-1',
				     String => <<"EOF;" } );
<!DOCTYPE foo
  [
    <!NOTATION bar PUBLIC "qrs">
    <!ENTITY zinger PUBLIC "xyz" "abc" NDATA bar>
    <!ENTITY fran "fran-def">
    <!ENTITY zoe  "zoe.ent">
   ]>
<foo>
  First line in foo
  <boom>Fran is &fran; and Zoe is &zoe;</boom>
  <bar id="jack" stomp="jill">
  <?line-noise *&*&^&<< ?>
    1st line in bar
    <blah> 2nd line in bar </blah>
    3rd line in bar <!-- Isn't this a doozy -->
  </bar>
  <zap ref="zing" />
  This, '\240', would be a bad character in UTF-8.
</foo>
EOF;

foreach $test (2..10) {
    print $subs->{Tests}[$test] ? "ok $test\n" : "not ok $test\n" ;
}

$expected = <<"EOF;";
<?xml version="1.0" encoding="UTF-8"?>
<foo>
  First line in foo
  <boom>Fran is fran-def and Zoe is zoe.ent</boom>
  <bar id="jack" stomp="jill">
  <?line-noise *&*&^&<< ?>
    1st line in bar
    <blah> 2nd line in bar </blah>
    3rd line in bar <!--  Isn't this a doozy  -->
  </bar>
  <zap fubar="1" ref="zing"></zap>
  This, '\240', would be a bad character in UTF-8.
</foo>
EOF;

print (($string eq $expected) ? "ok 11\n" : "not ok 11\n");

package MySubs;
use vars qw{ @ISA };
BEGIN { @ISA = qw{ XML::Handler::XMLWriter }; };

sub s_zap {
    my ($self, $element) = @_;

    $self->{Tests}[2] = 1;  # we got here
    $self->{Tests}[3] = 1
	if $element->{Name} eq 'zap';
    $self->{Tests}[4] = 1
	if $element->{Name} eq $self->{Names}[-1];
    $self->{Tests}[5] = 1
	if $element == $self->{Nodes}[-1];
    $self->{Tests}[6] = 1
	if $#{$self->{Names}} == 1;
    $self->{Tests}[7] = 1
	if $#{$self->{Nodes}} == 1;

    $element->{Attributes}{'fubar'} = 1;

    $self->print_start_element($element);
}

sub e_zap {
    my ($self, $element) = @_;

    $self->{Tests}[8] = 1;  # we got here
    $self->{Tests}[9] = 1
	if $self->in_element('zap');
    $self->{Tests}[10] = 1
	if $self->within_element('zap') == 1;

    $self->print_end_element($element);
}

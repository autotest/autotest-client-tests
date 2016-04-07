# Hey Emacs, this is -*- perl -*- !
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: subs.t,v 1.1 1999/08/16 16:04:03 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Parser::PerlSAX;
use XML::Handler::Subs;


$loaded = 1;
print "ok 1\n";

my $subs = MySubs->new( );
my $parser = XML::Parser::PerlSAX->new( Handler => $subs );
$parser->parse(Source => { String => <<'EOF' } );
<foo:-it>
  <bar/>
</foo:-it>
EOF

foreach $test (2..10) {
    print $subs->{Tests}[$test] ? "ok $test\n" : "not ok $test\n" ;
}

package MySubs;
use vars qw{ @ISA };
BEGIN { @ISA = qw{ XML::Handler::Subs }; };

sub s_foo__it {
    my ($self, $element) = @_;

    $self->{Tests}[2] = 1;  # we got here
    $self->{Tests}[3] = 1
	if $element->{Name} eq 'foo:-it';
    $self->{Tests}[4] = 1
	if $element->{Name} eq $self->{Names}[-1];
    $self->{Tests}[5] = 1
	if $element == $self->{Nodes}[-1];
    $self->{Tests}[6] = 1
	if $#{$self->{Names}} == 0;
    $self->{Tests}[7] = 1
	if $#{$self->{Nodes}} == 0;
}

sub e_foo__it {
    my ($self, $element) = @_;

    $self->{Tests}[8] = 1;  # we got here
    $self->{Tests}[9] = 1
	if $self->in_element('foo:-it');
    $self->{Tests}[10] = 1
	if $self->within_element('foo:-it') == 1;
}

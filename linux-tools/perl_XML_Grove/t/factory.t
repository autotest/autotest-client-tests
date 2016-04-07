# Hey, emacs!  This is -*- perl -*-
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# $Id: factory.t,v 1.1 1999/09/03 21:41:00 kmacleod Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Grove;
use XML::Grove::Factory;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$gf = XML::Grove::Factory->grove_factory;

$element = 
    $gf->element('HTML',
		 $gf->element('HEAD',
			      $gf->element('TITLE', 'Some Title')),
		 $gf->element('BODY', { bgcolor => '#FFFFFF' },
			      $gf->element('P', 'A paragraph.')));

print ((check_result($element)) ? "ok 2\n" : "not ok 2\n");

$ef = XML::Grove::Factory->element_factory();

$element =
    $ef->HTML(
	      $ef->HEAD(
			$ef->TITLE('Some Title')),
	      $ef->BODY({ bgcolor => '#FFFFFF' },
			$ef->P('A paragraph.')));

print ((check_result($element)) ? "ok 3\n" : "not ok 3\n");

XML::Grove::Factory->element_functions('', qw{ HTML HEAD TITLE BODY P });

$element =
    HTML(
	 HEAD(
	      TITLE('Some Title')),
	 BODY({ bgcolor => '#FFFFFF' },
	      P('A paragraph.')));

print ((check_result($element)) ? "ok 4\n" : "not ok 4\n");

$element = Factory_Test->doit();

print ((check_result($element)) ? "ok 5\n" : "not ok 5\n");

sub check_result {
    my $element = shift;

    if (ref($element) ne 'XML::Grove::Element') {
	warn "err 1\n";
	return 0;
    } elsif ($element->{Name} ne 'HTML') {
	warn "err 2\n";
	return 0;
    } elsif (ref($element->{Contents}[0]) ne 'XML::Grove::Element') {
	warn "err 3\n";
	return 0;
    } elsif ($element->{Contents}[0]{Name} ne 'HEAD') {
	warn "err 4\n";
	return 0;
    } elsif (ref($element->{Contents}[1]) ne 'XML::Grove::Element') {
	warn "err 5\n";
	return 0;
    } elsif ($element->{Contents}[1]{Name} ne 'BODY') {
	warn "err 6\n";
	return 0;
    } elsif ($element->{Contents}[1]{Attributes}{'bgcolor'}
	     ne '#FFFFFF') {
	warn "err 7\n";
	return 0;
    } elsif (ref($element->{Contents}[0]{Contents}[0])
	     ne 'XML::Grove::Element') {
	warn "err 8\n";
	return 0;
    } elsif ($element->{Contents}[0]{Contents}[0]{Name} ne 'TITLE') {
	warn "err 9\n";
	return 0;
    } elsif ($element->{Contents}[0]{Contents}[0]{Contents}[0]{Data}
	     ne 'Some Title') {
	warn "err 10\n";
	return 0;
    } elsif (ref($element->{Contents}[1]{Contents}[0])
	     ne 'XML::Grove::Element') {
	warn "err 11\n";
	return 0;
    } elsif ($element->{Contents}[1]{Contents}[0]{Name} ne 'P') {
	warn "err 12\n";
	return 0;
    } elsif ($element->{Contents}[1]{Contents}[0]{Contents}[0]{Data}
	     ne 'A paragraph.') {
	warn "err 13\n";
	return 0;
    }

    return 1;
}

# This package checks the ability to create functions inside the
# class, I think
package Factory_Test;

sub doit {
    XML::Grove::Factory->element_functions('', qw{ HTML HEAD
						   TITLE BODY P });

    return HTML(
		HEAD(
		     TITLE('Some Title')),
		BODY({ bgcolor => '#FFFFFF' },
		     P('A paragraph.')));
}

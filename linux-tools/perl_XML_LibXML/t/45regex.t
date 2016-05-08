#########################

use strict;
use warnings;

use Test::More tests => 13;

use XML::LibXML;

{
    my $regex = '[0-9]{5}(-[0-9]{4})?';
    my $re = XML::LibXML::RegExp->new($regex);

    # TEST
    ok( $re, 'Regex object was initted.');
    # TEST
    ok( ! $re->matches('00'), 'Does not match 00' );
    # TEST
    ok( ! $re->matches('00-'), 'Does not match 00-' );
    # TEST
    ok( $re->matches('12345'), 'Matches 12345' );
    # TEST
    ok( !$re->matches('123456'), 'Does not match 123456' );

    # TEST
    ok( $re->matches('12345-1234'), 'Matches 12345-1234');
    # TEST
    ok( ! $re->matches(' 12345-1234'), 'Does not match leading space');
    # TEST
    ok( ! $re->matches(' 12345-12345'), 'Leading space No. 2' );
    # TEST
    ok( ! $re->matches('12345-1234 '), 'Trailing space' );

    # TEST
    ok( $re->isDeterministic, 'Regex is deterministic' );
}

{
    my $nondet_regex = '(bc)|(bd)';
    my $nondet_re = XML::LibXML::RegExp->new($nondet_regex);

    # TEST
    ok( $nondet_re, 'Non deterministic re was initted' );
    # TEST
    ok( ! $nondet_re->isDeterministic, 'It is not deterministic' );
}

{
    my $bad_regex = '[0-9]{5}(-[0-9]{4}?';
    eval { XML::LibXML::RegExp->new($bad_regex); };
    # TEST
    ok( $@, 'An exception was thrown on bad regex' );
}

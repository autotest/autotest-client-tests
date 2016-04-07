#!perl
use strict;
use warnings;
use Test::More tests => 11;
use FindBin qw($Bin);
require "$Bin/../lib/common.pl";

## base conf
my $cconf = {
    sasl => {
        mechanism => 'DIGEST-MD5',
        callback => {
            user => 'yann',
            pass => 'maelys',
        },
    },
    host => 'localhost',
    security => 'noanonymous',
    service => 'xmpp',
};

my $sconf = {
    sasl => {
        mechanism => 'DIGEST-MD5',
        callback => {
            getsecret => sub { $_[2]->('maelys') },
        },
    },
    host => 'localhost',
    service => 'xmpp',
};

## base negotiation should work
negotiate($cconf, $sconf, sub {
    my ($clt, $srv) = @_;
    ok $clt->is_success, "client success" or diag $clt->error;
    ok $srv->is_success, "server success" or diag $srv->error;
});

## invalid password
{
    local $cconf->{sasl}{callback}{pass} = "YANN";

    negotiate($cconf, $sconf, sub {
        my ($clt, $srv) = @_;
        ok !$srv->is_success, "failure";
        like $srv->error, qr/response/;
    });
}

## arguments passed to server pass callback
{
    local $cconf->{sasl}{callback}{authname} = "some authzid";
    local $sconf->{sasl}{callback}{getsecret} = sub {
        my $server = shift;
        my ($args, $cb) = @_;
        is $args->{user},     "yann",         "username";
        is $args->{realm},    "localhost",    "realm";
        is $args->{authzid},  "some authzid", "authzid";
        $cb->("incorrect");
    };

    negotiate($cconf, $sconf, sub {
        my ($clt, $srv) = @_;
        ok !$srv->is_success, "failure";
        like $srv->error, qr/response/, "incorrect response";
    });
}

## digest-uri checking
{
    local $cconf->{host}    = "elsewhere";
    local $cconf->{service} = "pop3";
    negotiate($cconf, $sconf, sub {
        my ($clt, $srv) = @_;
        ok !$srv->is_success, "failure";
        my $error = $srv->error || "";
        like $error, qr/incorrect.*digest.*uri/i, "incorrect digest uri";
    });
}

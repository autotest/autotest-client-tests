use strict;
use warnings;

use Authen::SASL ('Perl');

sub negotiate {
    my ($c, $s, $do) = @_;

    my $client_sasl = Authen::SASL->new( %{ $c->{sasl} } );
    my $server_sasl = Authen::SASL->new( %{ $s->{sasl} } );

    my $client = $client_sasl->client_new(@$c{qw/service host security/});
    my $server = $server_sasl->server_new(@$s{qw/service host/});

    my $start     = $client->client_start();

    my $challenge;
    my $next_cb = sub { $challenge = shift };
    $server->server_start($start, $next_cb);

    my $response;
    ## note: this wouldn't work in a real async environment
    while ($client->need_step || $server->need_step) {
        $response = $client->client_step($challenge)
            if $client->need_step;
        last if $client->error;
        $server->server_step($response, $next_cb)
            if $server->need_step;
        last if $server->error;
    }
    $do->($client, $server);
}

1;

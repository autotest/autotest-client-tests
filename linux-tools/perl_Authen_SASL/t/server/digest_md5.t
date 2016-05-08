#!perl
use strict;
use warnings;

BEGIN {
    require Test::More;
    eval { require Digest::MD5      } or Test::More->import(skip_all => 'Need Digest::MD5');
    eval { require Digest::HMAC_MD5 } or Test::More->import(skip_all => 'Need Digest::HMAC_MD5');
}

use Test::More (tests => 33);

use Authen::SASL qw(Perl);
use_ok 'Authen::SASL::Perl::DIGEST_MD5';

my $authname;

my $sasl = Authen::SASL->new(
    mechanism => 'DIGEST-MD5',
    callback => {
        getsecret => sub { $_[2]->('fred') },
    },
);
ok($sasl,'new');

no warnings 'once';
# override for testing as by default it uses $$, time and rand
$Authen::SASL::Perl::DIGEST_MD5::NONCE = "foobaz";

is($sasl->mechanism, 'DIGEST-MD5', 'sasl mechanism');
my $server = $sasl->server_new("ldap","elwood.innosoft.com", { no_integrity => 1 });
is($server->mechanism, 'DIGEST-MD5', 'conn mechanism');

## simple success without authzid
{
    my $expected_ss = join ",",
        'algorithm=md5-sess',
        'charset=utf-8',
        'cipher="rc4,3des,des,rc4-56,rc4-40"',
        'maxbuf=16777215',
        'nonce="80338e79d2ca9b9c090ebaaa2ef293c7"',
        'qop="auth"',
        'realm="elwood.innosoft.com"';

    my $ss;
    $server->server_start('', sub { $ss = shift });
    is($ss, $expected_ss, 'server_start');

    my $c1 = join ",", qw(
        charset=utf-8
        cnonce="3858f62230ac3c915f300c664312c63f"
        digest-uri="ldap/elwood.innosoft.com"
        nc=00000001
        nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
        qop=auth
        realm="elwood.innosoft.com"
        response=39ab7388b1f52492b1b87cda55177d04
        username="gbarr"
    );

    my $s1;
    $server->server_step($c1, sub { $s1 = shift });
    ok  $server->is_success, "This is the first and only step";
    ok !$server->error, "no error" or diag $server->error;
    ok !$server->need_step, "over";
    is $server->property('ssf'), 0, "auth doesn't provide any protection";
    is($s1, "rspauth=dbf4b44d397bafd53be835344988ec9d", "rspauth matches");
}

# try with an authname
{
    my $expected_ss = join ",",
        'algorithm=md5-sess',
        'charset=utf-8',
        'cipher="rc4,3des,des,rc4-56,rc4-40"',
        'maxbuf=16777215',
        'nonce="80338e79d2ca9b9c090ebaaa2ef293c7"',
        'qop="auth"',
        'realm="elwood.innosoft.com"';

    my $ss;
    $server->server_start('', sub { $ss = shift });
    is($ss, $expected_ss, 'server_start');
    ok !$server->is_success, "not success yet";
    ok !$server->error, "no error" or diag $server->error;
    ok  $server->need_step, "we need one more step";

    $authname = 'meme';

    my $c1 = join ",", qw(
        authzid="meme"
        charset=utf-8
        cnonce="3858f62230ac3c915f300c664312c63f"
        digest-uri="ldap/elwood.innosoft.com"
        nc=00000002
        nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
        qop=auth
        realm="elwood.innosoft.com"
        response=e01f51543754aa665cfa2c621d59ee9e
        username="gbarr"
    );

    my $s1;
    $server->server_step($c1, sub { $s1 = shift });
    is($s1, "rspauth=d10458627b2b6bb553d796f4d805fdd1", "rspauth")
        or diag $server->error;
    ok $server->is_success, "success!";
    ok !$server->error, "no error" or diag $server->error;
    ok !$server->need_step, "over";
    is $server->property('ssf'), 0, "auth doesn't provide any protection";
}

## using auth-conf (if available)
{
    SKIP: {
        skip "Crypt not available", 6
            if $Authen::SASL::Perl::DIGEST_MD5::NO_CRYPT_AVAILABLE;

        $server = $sasl->server_new("ldap","elwood.innosoft.com");
        my $expected_ss = join ",",
            'algorithm=md5-sess',
            'charset=utf-8',
            'cipher="rc4,3des,des,rc4-56,rc4-40"',
            'maxbuf=16777215',
            'nonce="80338e79d2ca9b9c090ebaaa2ef293c7"',
            'qop="auth,auth-conf,auth-int"',
            'realm="elwood.innosoft.com"';

        my $ss;
        $server->server_start('', sub { $ss = shift });
        is($ss, $expected_ss, 'server_start');

        my $c1 = join ",", qw(
            charset=utf-8
            cnonce="3858f62230ac3c915f300c664312c63f"
            digest-uri="ldap/elwood.innosoft.com"
            nc=00000001
            nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
            qop=auth-conf
            realm="elwood.innosoft.com"
            response=e3c8b38d9bd9556761253e9879c4a8a2
            username="gbarr"
        );

        my $s1;
        $server->server_step($c1, sub { $s1 = shift });
        ok  $server->is_success, "This is the first and only step";
        ok !$server->error, "no error" or diag $server->error;
        ok !$server->need_step, "over";
        is($s1, "rspauth=1b1156d0e7f046bd0ea1476eb7d63a7b", "rspauth matches");

        ## we have negociated the conf layer
        ok $server->property('ssf') > 1, "yes! secure layer set up";
    };
}
## wrong challenge response
{
    $server = $sasl->server_new("ldap","elwood.innosoft.com");
    $server->server_start('');

    my $c1 = join ",", qw(
        charset=utf-8
        cnonce="3858f62230ac3c915f300c664312c63f"
        digest-uri="ldap/elwood.innosoft.com"
        nc=00000001
        nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
        qop=auth-conf
        realm="elwood.innosoft.com"
        response=nottherightone
        username="gbarr"
    );

    $server->server_step($c1);
    ok !$server->is_success, "Bad challenge";

    if ($Authen::SASL::Perl::DIGEST_MD5::NO_CRYPT_AVAILABLE) {
        like $server->error, qr/Client qop not supported/, $server->error;
    }
    else {
        like $server->error, qr/incorrect.*response/i, $server->error;
    }
}

## multiple digest-uri;
{
    $server = $sasl->server_new("ldap","elwood.innosoft.com");
    $server->server_start('');

    my $c1 = join ",", qw(
        charset=utf-8
        cnonce="3858f62230ac3c915f300c664312c63f"
        digest-uri="ldap/elwood.innosoft.com"
        digest-uri="ldap/elwood.innosoft.com"
        nc=00000001
        nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
        qop=auth-conf
        realm="elwood.innosoft.com"
        response=e3c8b38d9bd9556761253e9879c4a8a2
        username="gbarr"
    );

    $server->server_step($c1);
    ok !$server->is_success, "Bad challenge";
    like $server->error, qr/Bad.*challenge/i, $server->error;
}

## nonce-count;
{
    $server = $sasl->server_new("ldap","elwood.innosoft.com");
    $server->server_start('');

    my $c1 = join ",", qw(
        charset=utf-8
        cnonce="3858f62230ac3c915f300c664312c63f"
        digest-uri="ldap/elwood.innosoft.com"
        nc=00000001
        nonce="80338e79d2ca9b9c090ebaaa2ef293c7"
        qop=auth-conf
        realm="elwood.innosoft.com"
        response=e3c8b38d9bd9556761253e9879c4a8a2
        username="gbarr"
    );

    SKIP: {
        skip "no crypt available", 4
            if $Authen::SASL::Perl::DIGEST_MD5::NO_CRYPT_AVAILABLE;
        $server->server_step($c1);
        ok $server->is_success, "first is success";
        ok ! $server->error, "no error";

        $server->server_step($c1);
        ok !$server->is_success, "replay attack";
        like $server->error, qr/nonce-count.*match/i, $server->error;
    }
}

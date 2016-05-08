#!perl
use strict;
use warnings;

use Test::More tests => 67;

use Authen::SASL qw(Perl);
use_ok('Authen::SASL::Perl::PLAIN');

my %creds = (
    default => {
        yann => "maelys",
        YANN => "MAELYS",
    },
    none => {
        yann => "maelys",
        YANN => "MAELYS",
    },
);

my %params = (
  mechanism => 'PLAIN',
  callback => {
    getsecret => sub {
        my $self = shift;
        my ($args, $cb) = @_;
        $cb->($creds{$args->{authname} || "default"}{$args->{user} || ""});
    },
    checkpass => sub {
        my $self = shift;
        my ($args, $cb) = @_;
        $args ||= {};
        my $username = $args->{user};
        my $password = $args->{pass};
        my $authzid  = $args->{authname};
        unless ($username) {
            $cb->(0);
            return;
        }
        my $expected = $creds{$authzid || "default"}{$username};
        if ($expected && $expected eq ($password || "")) {
            $cb->(1);
        }
        else {
            $cb->(0);
        }
        return;
    },
  },
);

ok(my $ssasl = Authen::SASL->new( %params ), "new");

is($ssasl->mechanism, 'PLAIN', 'sasl mechanism');

my $server = $ssasl->server_new("ldap","localhost");
is($server->mechanism, 'PLAIN', 'server mechanism');

for my $authname ('', 'none') {
    is_failure("");
    is_failure("xxx");
    is_failure("\0\0\0\0\0\0\0");
    is_failure("\0\0\0\0\0\0\0$authname\0yann\0maelys");
    is_failure("yann\0maelys\0$authname", "wrong order");
    is_failure("$authname\0YANN\0maelys", "case matters");
    is_failure("$authname\0yann\n\0maelys", "extra stuff");
    is_failure("$authname\0yann\0\0maelys", "double null");
    is_failure("$authname\0yann\0maelys\0trailing", "trailing");

    my $cb;
    $server->server_start("$authname\0yann\0maelys", sub { $cb = 1 });
    ok $cb, "callback called";
    ok $server->is_success, "success finally";
}

## testing checkpass callback, which takes precedence
## over getsecret when specified
%params = (
  mechanism => 'PLAIN',
  callback => {
    getsecret => sub { $_[2]->("incorrect") },
    checkpass => sub {
        my $self = shift;
        my ($args, $cb) = @_;
        is $args->{user},     "yyy", "username correct";
        is $args->{pass},     "zzz", "correct password";
        is $args->{authname}, "xxx", "correct realm";
        $cb->(1);
        return;
    }
  },
);

ok($ssasl = Authen::SASL->new( %params ), "new");
$server = $ssasl->server_new("ldap","localhost");
$server->server_start("xxx\0yyy\0zzz");
ok $server->is_success, "success";

sub is_failure {
    my $creds = shift;
    my $msg   = shift;
    my $cb;
    $server->server_start($creds, sub { $cb = 1 });
    ok $cb, 'callback called';
    ok !$server->is_success, $msg || "failure";
    my $error = $server->error || "";
    like $error, qr/match/i, "failure";
}


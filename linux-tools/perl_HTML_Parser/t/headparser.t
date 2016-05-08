#!perl -w

use strict;
use Test::More tests => 17;

{ package H;
  sub new { bless {}, shift; }

  sub header {
     my $self = shift;
     my $key  = uc(shift);
     die if $key =~ /:/;
     my $old = $self->{$key};
     if (@_) { $self->{$key} = shift; }
     $old;
  }

  sub push_header {
     my($self, $k, $v) = @_;
     $k = uc($k);
     die if $k =~ /:/;
     if (exists $self->{$k}) {
        $self->{$k} = [ $self->{$k} ] unless ref $self->{$k};
	push(@{$self->{$k}}, $v);
     } else {
	$self->{$k} = $v;
     }
  }

  sub as_string {
     my $self = shift;
     my $str = "";
     for (sort keys %$self) {
         if (ref($self->{$_})) {
            my $v;
            for $v (@{$self->{$_}}) {
	        $str .= "$_: $v\n";
            }
         } else {
            $str .= "$_: $self->{$_}\n";
         }
     }
     $str;
  }
}


my $HTML = <<'EOT';

<title>&Aring være eller &#229; ikke være</title>
<meta http-equiv="Expires" content="Soon">
<meta http-equiv="Foo" content="Bar">
<meta name='twitter:card' content='photo' />
<link href="mailto:gisle@aas.no" rev=made title="Gisle Aas">

<script>

    ignore this

</script>
<noscript> ... and this </noscript>

<object classid="foo">

<base href="http://www.sn.no">
<meta name="Keywords" content="test, test, test,...">
<meta name="Keywords" content="more">
<meta charset="ISO-8859-1"><!-- HTML 5 -->

Dette er vanlig tekst.  Denne teksten definerer også slutten på
&lt;head> delen av dokumentet.

<style>

   ignore this too

</style>

<isindex>

Dette er også vanlig tekst som ikke skal blir parset i det hele tatt.

EOT

$| = 1;

#$HTML::HeadParser::DEBUG = 1;
require HTML::HeadParser;
my $p = HTML::HeadParser->new( H->new );

if ($p->parse($HTML)) {
    fail("Need more data which should not happen");
} else {
    #diag $p->as_string;
    pass();
}

like($p->header('Title'), qr/Å være eller å ikke være/);
is($p->header('Expires'), 'Soon');
is($p->header('Content-Base'), 'http://www.sn.no');
is_deeply($p->header('X-Meta-Keywords'), ['test, test, test,...', 'more']);
is($p->header('X-Meta-Charset'), 'ISO-8859-1');
is($p->header('X-Meta-Twitter-Card'), 'photo');
like($p->header('Link'), qr/<mailto:gisle\@aas.no>/);

# This header should not be present because the head ended
ok(!$p->header('Isindex'));


# Try feeding one char at a time
my $expected = $p->as_string;
my $nl = 1;
$p = HTML::HeadParser->new(H->new);
while ($HTML =~ /(.)/sg) {
    #print STDERR '#' if $nl;
    #print STDERR $1;
    $nl = $1 eq "\n";
    $p->parse($1) or last;
}
is($p->as_string, $expected);


# Try reading it from a file
my $file = "hptest$$.html";
die "$file already exists" if -e $file;

open(FILE, ">$file") or die "Can't create $file: $!";
binmode(FILE);
print FILE $HTML;
print FILE "<p>This is more content...</p>\n" x 2000;
print FILE "<title>Buuuh!</title>\n" x 200;
close FILE or die "Can't close $file: $!";

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

is($p->header("Title"), "Å være eller å ikke være");


# We got into an infinite loop on data without tags and no EOL.
# This was actually a HTML::Parser bug.
open(FILE, ">$file") or die "Can't create $file: $!";
print FILE "Foo";
close(FILE);

$p = HTML::HeadParser->new(H->new);
$p->parse_file($file);
unlink($file) or warn "Can't unlink $file: $!";

ok(!$p->as_string);

SKIP: {
  skip "Need Unicode support", 5 if $] < 5.008;

  # Test that the Unicode BOM does not confuse us?
  $p = HTML::HeadParser->new(H->new);
  ok($p->parse("\x{FEFF}\n<title>Hi <foo></title>"));
  $p->eof;

  is($p->header("title"), "Hi <foo>");

  $p = HTML::HeadParser->new(H->new);
  $p->utf8_mode(1);
  $p->parse(<<"EOT");  # example from http://rt.cpan.org/Ticket/Display.html?id=27522
\xEF\xBB\xBF<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
 <head>
 <title>
Parkinson's disease</title>
 <meta name="Keywords" content="brain,disease,dopamine,drug,levodopa,parkinson,patients,symptoms,,Medications, Medications">
 </meta>
 \t
\t<link href="../../css/ummAdam.css" rel="stylesheet" type="text/css" />
\t<link rel="stylesheet" rev="stylesheet" href="../../css/ummprint.css" media="print" />
\t
\t </head>
 <body>
EOT
  $p->eof;

  is($p->header("title"), "Parkinson's disease");
  is($p->header("link")->[0], '<../../css/ummAdam.css>; rel="stylesheet"; type="text/css"');

  $p = HTML::HeadParser->new(H->new);
  $p->utf8_mode(1);
  $p->parse(<<"EOT");   # example from http://www.mjw.com.pl/
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\r
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="pl" lang="pl"> \r
\r
<head profile="http://gmpg.org/xfn/11">\r
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />\r
\r
<title> ko\xC5\x84c\xC3\xB3wki kolekcji, outlet, hurtownia odzie\xC5\xBCy Warszawa &#8211; MJW</title>\r
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />\r

EOT
    $p->eof;
    is($p->header("title"), "ko\xC5\x84c\xC3\xB3wki kolekcji, outlet, hurtownia odzie\xC5\xBCy Warszawa \xE2\x80\x93 MJW");
}

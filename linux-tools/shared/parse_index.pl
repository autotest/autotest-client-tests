#!/usr/bin/perl

use HTML::TokeParser;
$p = HTML::TokeParser->new(shift||"centos");

while (my $token = $p->get_tag("a")) {
      my $url = $token->[1]{href} || "-";
      my $text = $p->get_trimmed_text("/a");
      print "$url\n"; }

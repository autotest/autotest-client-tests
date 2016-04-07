#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }
require "test_data/gen_test_data.pl";

gen("foo");
use Locale::gettext;
my $d;
eval {
	$d = Locale::gettext->domain("foo");
};
if ($@ =~ /Encode module not available/) {
	skip("Locale::gettext->domain not available, skipping", 0)
} elsif ($@ ne '') {
	die $@;
} else {
	$d->dir("test_data");
	if ($d->get("No problem") eq "Pas de probl\x{e8}me") {
		ok(1);
	} else {
use Data::Dumper;
print Dumper($d);
print "[", $d->get("No problem"), "]\n";
		ok(0);
	}
}
exit;
__END__

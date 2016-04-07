#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }
require "test_data/gen_test_data.pl";

gen("jaeuc");
use Locale::gettext;
my $d;
eval {
	$d = Locale::gettext->domain("jaeuc");
};
if ($@ =~ /Encode module not available/) {
	skip("Locale::gettext->domain not available, skipping", 0)
} elsif ($@ ne '') {
	die $@;
} else {
	$d->dir("test_data");
	if ($d->get("test") eq "\x{30c6}\x{30b9}\x{30c8}") {
		ok(1);
	} else {
		print $d->get("test"), "\n";
		ok(0);
	}
}
exit;
__END__

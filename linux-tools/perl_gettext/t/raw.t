#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }
require "test_data/gen_test_data.pl";

gen("foo");
use Locale::gettext;
my $d = Locale::gettext->domain_raw("foo");
$d->dir("test_data");
if ($d->get("No worries") eq "Sans craintes") {
	ok(1);
} else {
	ok(0);
}
undef $d;
exit;
__END__

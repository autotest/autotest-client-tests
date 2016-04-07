# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;

BEGIN { plan tests => 21, todo => [] };

use Net::LibIDN;

#########################

ok(Net::LibIDN::idn_to_ascii("b\xF6se.de", "ISO-8859-1"), "xn--bse-sna.de");
ok(Net::LibIDN::idn_to_ascii("b\xC3\xB6se.de","UTF-8"), "xn--bse-sna.de");

ok(Net::LibIDN::idn_to_unicode("xn--bse-sna.de", "ISO-8859-1"), "b\xF6se.de");
ok(Net::LibIDN::idn_to_unicode("xn--bse-sna.de", "UTF-8"), "b\xC3\xB6se.de");

ok(Net::LibIDN::idn_punycode_encode("\xDCHHH\xC4AHHH", "ISO-8859-1"), "HHHAHHH-wpa6s");
ok(Net::LibIDN::idn_punycode_encode("\xC3\x9CHHH\xC3\x84AHHH", "UTF-8"), "HHHAHHH-wpa6s");

ok(Net::LibIDN::idn_punycode_decode("HHHAHHH-wpa6s", "ISO-8859-1"), "\xDCHHH\xC4AHHH");
ok(Net::LibIDN::idn_punycode_decode("HHHAHHH-wpa6s", "UTF-8"), "\xC3\x9CHHH\xC3\x84AHHH");

ok(Net::LibIDN::idn_prep_name("GR\xD6\xDFeR", "ISO-8859-1"), "gr\xF6sser");
ok(Net::LibIDN::idn_prep_name("GR\xC3\xB6\xC3\x9Fer", "UTF-8"), "gr\xC3\xB6sser");


my $has_nono;

{
my $res = Net::LibIDN::tld_get_table("no");
$has_nono = $$res{name} ne "no";
skip($has_nono, $$res{name}, "no");
skip($has_nono, $$res{nvalid}, 13);
my $sum = 0;
my $zero = 0;
for (my $i=0; $i<13; $i++)
{
	$zero = 1 if (!$$res{valid}[$i]{start} && !$$res{valid}[$i]{end});
	$sum += $$res{valid}[$i]{start};
	$sum += $$res{valid}[$i]{end};
}
skip($has_nono, $sum, 7470);
skip($has_nono, $zero, 0);
}


{
my $errpos;
my $res = Net::LibIDN::tld_check("p\xFBrle.no", $errpos, "ISO-8859-1");
skip($has_nono, $errpos, 1);
skip($has_nono, $res, 0);
}

{
my $errpos;
my $res = Net::LibIDN::tld_check("p\xFBrle.no", $errpos, "ISO-8859-1", "com");
ok($errpos, 0);
ok($res, 1);
}

ok(Net::LibIDN::tld_get("Kruder.DorfMeister"), "dorfmeister");
ok(Net::LibIDN::tld_get("GR\xC3\xB6\xC3\x9Fer"), undef);

ok(Net::LibIDN::tld_get_table("mars"), undef);


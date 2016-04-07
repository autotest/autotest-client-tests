#!perl

use Test::More;
use File::Compare qw(compare_text);

BEGIN { require "t/common.pl" }


(eval { require XML::SAX::Base } && eval { require XML::SAX::Writer })
? plan tests => 1
: plan skip_all => 'XML::SAX::Base and XML::SAX::Writer need to be installed';


require Net::LDAP::LDIF;
require Net::LDAP::DSML;

my $infile   = "data/00-in.ldif";
my $outfile1 = "$TEMPDIR/05-out1.dsml";
my $cmpfile1 = "data/05-cmp.dsml";

my $ldif = Net::LDAP::LDIF->new($infile,"r");

@entry = $ldif->read;

open(FH,">$outfile1");
binmode FH;
my $dsml = Net::LDAP::DSML->new(output => \*FH,pretty_print => 1);

$dsml->write_entry($_) for @entry;

$dsml->end_dsml;
close(FH);

# postprocess generated DSML file for more flexible comparison
# (don't rely on unpatched XML::SAX::Writer [e.g. Debian])
{
open(FH, "+<$outfile1");
binmode FH;
local $/;	# slurp mode
my $txt = <FH>;

$txt =~ s/>\n[\n\t ]+/>\n/g;	# remove empty lines & leading spaces after tags
$txt =~ s/\"/'/g;	# convert " to ' in tag attribute values

seek(FH, 0, 0);
print FH $txt;
truncate(FH, length($txt));
close(FH);
}

ok(!compare_text($cmpfile1,$outfile1), $cmpfile1);

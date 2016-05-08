use strict;
use warnings;

use Test;
use XML::Dumper;

BEGIN { plan tests => 2 }

# ===== IT LOADS AND PARSES
ok( 1 );

# ===== IT INSTANTIATES
my $dump = new XML::Dumper;
ok( 2 );


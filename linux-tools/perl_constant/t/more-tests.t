#!perl -T
use strict;
use warnings;
use vars qw{ @warnings };
use Test::More;


BEGIN {
    plan skip_all => "Author tests" unless $ENV{AUTHOR_MODE};
    plan tests => 4;
}

BEGIN {                         # ...and save 'em for later
    $SIG{'__WARN__'} = sub { push @warnings, @_ }
}
END { @warnings && print STDERR join "\n- ", "unexpected warnings:", @warnings }


my $TB = Test::More->builder;

BEGIN { use_ok('constant'); }


# The original test code was:
# 
#   use constant TRAILING   => '12 cats';
#   {
#       no warnings "numeric";
#       cmp_ok TRAILING, '==', 12;
#   }
#
# It worked fine during a long time (at least for some value of "work"),
# until the combination of two independant modifications. First, Sebastien
# Aperghis-Tramoni replaced the C< no warnings "numeric" > with a 
# C< local $^W > when constant.pm was dual-lifed and ported back to 5.005
# (see change 31963).
#
# It still worked fine, but then Michael Schwern improved Test::Builder in
# version 0.82 by turning warnings on. This broke this test by generating
# a warning. The test was fixed, but Michael wondered if the test was 
# really appropriate, given it was more testing Perl itself than constant.pm.
# Sebastien asked P5P for advice: Nicholas Clark and Andy Dougherty were
# in favour of removing it. So it was moved from t/constant.t to this file, 
# in order to keep it while preventing it from being a problem.
#
use constant TRAILING   => '12 cats';
{
    no warnings "numeric";
    ok( TRAILING == 12 ) or diag sprintf "'%s' == 12", TRAILING;
    @warnings = () if $] <= 5.006;  # we can't hide this warning under 5.005
}
is TRAILING, '12 cats';


is @warnings, 0 or diag join "\n- ", "unexpected warning", @warnings;

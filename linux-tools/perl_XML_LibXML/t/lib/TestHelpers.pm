package TestHelpers;

use strict;
use warnings;

our @EXPORT = (qw(slurp utf8_slurp eq_or_diff));

use base 'Exporter';

use Test::More ();

sub slurp
{
    my $filename = shift;

    open my $in, "<", $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

sub utf8_slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    binmode $in, ':utf8';

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

my $_eq_or_diff_ref;

if (eval "require Test::Differences; 1;" && (!$@))
{
    $_eq_or_diff_ref = \&Test::Differences::eq_or_diff;
}
else
{
    $_eq_or_diff_ref = \&Test::More::is_deeply;
}

sub eq_or_diff
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return $_eq_or_diff_ref->(@_);
}

1;

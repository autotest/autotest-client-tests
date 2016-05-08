
# check that the filters are destroyed in the correct order by
# installing two different types of filter. If they don't get destroyed
# in the correct order we should get a "filter_del can only delete in
# reverse order" error

# skip this set of tests is running on anything less than 5.004_55
if ($] < 5.004_55) {
    print "1..0\n";
    exit 0;
}

use strict;
use warnings;

require "./filter-util.pl" ;

use vars qw( $Inc $Perl) ;

my $file = "tee.test" ;
my $module = "FilterTry";
my $tee1 = "tee1" ;
$Inc .= " -It";

writeFile("t/${module}.pm", <<EOM, <<'EOM') ;
package ${module} ;

EOM
use Filter::Util::Call ;
sub import {
    filter_add(
        sub {

            my ($status) ;

            if (($status = filter_read()) > 0) {
                s/ABC/DEF/g
            }
            $status ;
        } ) ;
}

1;
__END__

=head1 NAME

FilterTry - Perl Source Filter Example Module created by t/order.t

=head1 SYNOPSIS

    use FilterTry ;
    sourcecode...

=cut
EOM

my $fil1 = <<"EOM";
use $module ;

print "ABC ABC\n" ;

EOM

writeFile($file, <<"EOM", $fil1) ;
use Filter::tee '>$tee1' ;
EOM

my $a = `$Perl $Inc $file 2>&1` ;

print "1..3\n" ;

ok(1, ($? >> 8) == 0) ;
chomp $a; 	# strip crlf resp. lf
#print "|$a|\n";
ok(2, $a eq "DEF DEF");

my $readtee1 = readFile($tee1);
if ($^O eq 'MSWin32') {
   $readtee1 =~ s/\r//g;
}
ok(3, $fil1 eq $readtee1) ;

unlink $file or die "Cannot remove $file: $!\n" ;
unlink $tee1 or die "Cannot remove $tee1: $!\n" ;

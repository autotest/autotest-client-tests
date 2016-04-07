
use strict;
use warnings;

require "./filter-util.pl" ;

use vars qw( $Inc $Perl $tee1) ;

my $file = "tee.test" ;
$tee1 = "tee1" ;
my $tee2 = "tee2" ;


my $out1 = <<"EOF" ;
use Filter::tee '>$tee1' ; 
EOF

my $out2 = <<"EOF" ;
use Filter::tee '>>$tee2' ; 
EOF

my $out3 = <<'EOF' ;

$a = 1 ;
print "a = $a\n" ;

use Carp ;
require "./joe" ;

print <<EOM ;
hello
horray

EOM

exit 0 ;

EOF

my $out4 = <<'EOM' ;
Here is the news
EOM

writeFile($file, $out1, $out2, $out3) ;
writeFile('joe', 'print "joe\n"') ;
writeFile($tee2, $out4) ;

my $a = `$Perl $Inc $file 2>&1` ;

print "1..5\n" ;

ok(1, ($? >> 8) == 0) ;
ok(2, $a eq <<EOM) ;
a = 1
joe
hello
horray

EOM

ok(3, $out2 . $out3 eq readFile($tee1)) ;
ok(4, $out4 . $out3 eq readFile($tee2)) ;

if ($< == 0 or ($^O =~ /MSWin32|cygwin|msys/)) {
    ok (5, 1); # windows allows all Administrator members read-access
} else {
    chmod 0444, $tee1 ;
    $a = `$Perl $Inc $file 2>&1` ;

    ok(5, $a =~ /cannot open file 'tee1':/) ;
}

unlink $file or die "Cannot remove $file: $!\n" ;
unlink 'joe' or die "Cannot remove joe: $!\n" ;
unlink $tee1 or die "Cannot remove $tee1: $!\n" ;
unlink $tee2 or die "Cannot remove $tee2: $!\n" ;

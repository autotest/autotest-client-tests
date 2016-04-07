
use strict;
use warnings;
use Config;

BEGIN
{
    my $foundTR = 0 ;
    if ($^O eq 'MSWin32') {
        # Check if tr is installed
        foreach (split ";", $ENV{PATH}) {
            if (-e "$_/tr.exe") {
                $foundTR = 1;
                last ;
            }
        }
    }
    else {
        $foundTR = 1
            if $Config{'tr'} ne '' ;
    }

    if (! $foundTR) {
        print "1..0 # Skipping tr not found on this system.\n" ;
        exit 0 ;
    }
}

require "filter-util.pl" ;

use vars qw( $Inc $Perl $script ) ;

$script = '';
if (eval {
    require POSIX;
    my $val = POSIX::setlocale(&POSIX::LC_CTYPE);
    $val !~ m{^(C|en)}
}) { # CPAN #41285
  $script = q(BEGIN { $ENV{LANG}=$ENV{LC_ALL}=$ENV{LC_CTYPE}='C'; });
}

$script .= <<"EOF" ;

use Filter::sh q(tr '[A-E][I-M]' '[a-e][i-m]') ;
use Filter::sh q(tr '[N-Z]' '[n-z]') ;

EOF

$script .= <<'EOF' ;

$A = 2 ;
PRINT "A = $A\N" ;

PRINT "HELLO JOE\N" ;
PRINT <<EOM ;
MARY HAD
A
LITTLE
LAMB
EOM
PRINT "A (AGAIN) = $A\N" ;
EOF

my $filename = 'sh.test' ;
writeFile($filename, $script) ;

my $expected_output = <<'EOM' ;
a = 2
Hello joe
mary Had
a
little
lamb
a (aGain) = 2
EOM

my $a = `$Perl $Inc $filename 2>&1` ;

print "1..2\n" ;
ok(1, ($? >> 8) == 0) ;
ok(2, $a eq $expected_output) ;

unlink $filename ;


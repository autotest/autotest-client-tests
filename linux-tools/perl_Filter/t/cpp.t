
use strict;
use warnings;
use Config;

BEGIN 
{
    my $cpp;
    my $sep;
    if ($^O eq 'MSWin32') {
        $cpp = 'cpp.exe' ;
        $sep = ';';
    }
    else {
        ($cpp) = $Config{cppstdin} =~ /^(\S+)/;
        $sep = ':';
    }
     
    if (! $cpp) {
        print "1..0 # Skipping cpp not found on this system.\n" ;
        exit 0 ;
    }
     
    # Check if cpp is installed
    if ( ! -x $cpp) {
        my $foundCPP = 0 ;
        foreach my $dir (split($sep, $ENV{PATH}), '')
        {
            if (-x "$dir/$cpp")
            {
                $foundCPP = 1;
                last ;
            }
        }
     
        if (! $foundCPP) {
            print "1..0 # Skipping cpp not found on this system.\n" ;
            exit 0 ;
        }
    }                              
}

use vars qw( $Inc $Perl ) ;

require "./filter-util.pl" ;

my $script = <<'EOF' ;
use Filter::cpp ;
#define FRED 1
#define JOE

#a perl comment, not a cpp line

$a = FRED + 2 ;
print "a = $a\n" ;

require "./fred" ;

#ifdef JOE
  print "Hello Joe\n" ;
#else
  print "Where is Joe?\n" ;
#endif
EOF

my $cpp_script = 'cpp.script' ;
writeFile($cpp_script, $script) ;
writeFile('fred', 'print "This is FRED, not JOE\n" ; 1 ;') ;

my $expected_output = <<'EOM' ;
a = 3
This is FRED, not JOE
Hello Joe
EOM

$a = `$Perl $Inc $cpp_script 2>&1` ;

print "1..2\n" ;
ok(1, ($? >>8) == 0) ;
#print "|$a| vs |$expected_output|\n";
ok(2, $a eq $expected_output) ;

unlink $cpp_script ;
unlink 'fred' ;

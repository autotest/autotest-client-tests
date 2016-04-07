
use strict;
use warnings;

require "filter-util.pl" ;
use Cwd ;
my $here = getcwd ;

use vars qw( $Inc $Perl ) ;

my $script = <<'EOM' ;

print "testing, testing, 1, 2, 3\n" ;
require "./plain" ;
use Cwd ;
$cwd = getcwd ;
print <<EOT ;
some
more test
lines
EOT

print "a multi-line
 string
$cwd\n" ;

format STDOUT_TOP =
I'm a format top
.

format STDOUT =
@<<<<<<<<<
"I'm not"
.


write ;
EOM

my $expected_output = <<EOM ;
testing, testing, 1, 2, 3
This is plain text
some
more test
lines
a multi-line
 string
$here
I'm a format top
I'm not
EOM

my $filename = "decrypt.tst" ;

writeFile($filename, $script) ;
`$Perl decrypt/encrypt $filename` ;
writeFile('plain', 'print "This is plain text\n" ; 1 ;') ;

my $a = `$Perl $Inc $filename 2>&1` ;

print "1..6\n" ;

print "# running perl with $Perl\n";
print "# test 1: \$? $?\n" unless ($? >>8) == 0 ;

ok(1, ($? >>8) == 0) ;
print "# test 2: Got '$a'\n" unless $a eq $expected_output ;
ok(2, $a eq $expected_output) ;

# try to catch error cases

# case 1 - Perl debugger
$ENV{'PERLDB_OPTS'} = 'noTTY' ;
$a = `$Perl $Inc -d $filename 2>&1` ;
print "# test 3: Got '$a'\n" unless $a =~ /debugger disabled/ ;
ok(3, $a =~ /debugger disabled/) ;

# case 2 - Perl Compiler in use
$a = `$Perl $Inc -MCarp -MO=Deparse $filename 2>&1` ;
#print "[[$a]]\n" ;
my $skip = "" ;
$skip = "# skipped -- compiler not available" 
    if $a =~ /^Can't locate O\.pm in/ ||
       $a =~ /^Can't load '/ ||
       $a =~ /^"my" variable \$len masks/ ;
print "# test 4: Got '$a'\n" unless $skip || $a =~ /Aborting, Compiler detected/;
ok(4, ($skip || $a =~ /Aborting, Compiler detected/), $skip) ;

# case 3 - unknown encryption
writeFile($filename, <<EOM) ;
use Filter::decrypt ;
mary had a little lamb
EOM

$a = `$Perl $Inc $filename 2>&1` ;

print "# test 5: Got '$a'\n" unless $a =~ /bad encryption format/ ;
ok(5, $a =~ /bad encryption format/) ;

# case 4 - extra source filter on the same line
writeFile($filename, <<EOM) ;
use Filter::decrypt ; use Filter::tee '/dev/null' ;
mary had a little lamb
EOM
 
$a = `$Perl $Inc $filename 2>&1` ;
print "# test 6: Got '$a'\n" unless $a =~ /too many filters/ ;
ok(6, $a =~ /too many filters/) ;

unlink $filename ;
unlink 'plain' ;

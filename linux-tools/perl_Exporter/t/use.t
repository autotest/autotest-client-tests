
print "1..1\n";

my $ok;
BEGIN { eval "use Exporter;"; $ok = !$@; }
print( ($ok ? '' : 'not '), "ok - use Exporter;\n" );

print( "# Testing Exporter $Exporter::VERSION, Perl $], $^X\n" );

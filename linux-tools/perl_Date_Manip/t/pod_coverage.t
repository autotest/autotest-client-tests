#!/usr/bin/perl

use Test::More;
use File::Basename;

if ($ENV{'TI_SKIPPOD'}) {
   plan skip_all => "POD tests skipped";
   exit;
}

# Find the test directory
#
# Scripts will either be run:
#    directly (look at $0)
#    as a test suite (look for ./t and ../t)

my($testdir);
if (-f "$0") {
   my $COM = $0;
   $testdir   = dirname($COM);
   $testdir   = '.'  if (! $testdir);
} elsif (-d 't') {
   $testdir   = 't';
} else {
   $testdir   = '.';
}

eval "use Test::Pod::Coverage 1.00";
if ($@) {
   plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage";
   exit;
}

@ign = ();
if (-f "$testdir/pod_coverage.ign") {
   open(IN,"$testdir/pod_coverage.ign");
   @ign = <IN>;
   close(IN);
   chomp(@ign);
}

if (@ign) {

   @mod = all_modules();

   MOD:
   foreach $mod (@mod) {
      foreach $ign (@ign) {
         next MOD  if ($mod =~ /^\Q$ign\E/);
      }
      pod_coverage_ok($mod);
   }
   done_testing();

} else {
   all_pod_coverage_ok();
}

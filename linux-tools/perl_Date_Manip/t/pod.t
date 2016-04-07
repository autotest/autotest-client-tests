#!/usr/bin/perl

use Test::More;

if ($ENV{'TI_SKIPPOD'}) {
   plan skip_all => "POD tests skipped";
   exit;
}

eval "use Test::Pod 1.00";
if ($@) {
   plan skip_all => "Test::Pod 1.00 required for testing POD files";
   exit;
}

all_pod_files_ok();

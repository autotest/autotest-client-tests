#!/usr/bin/perl

use strict;
BEGIN { $^W = 1 }

use Test::More;

plan tests => 1;

# Goal of these tests: confirm that Sub::Uplevel will work with Exporter's
# import() function

package main;
require t::lib::Importer;
require t::lib::Bar;
t::lib::Importer::import_for_me('t::lib::Bar','func3');
can_ok('main','func3');


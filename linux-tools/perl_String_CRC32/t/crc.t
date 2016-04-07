#!/usr/local/bin/perl  -I./blib/arch -I./blib/lib

require String::CRC32;

$string1 = "This is the test string";

$l1 = length($string1);

print "1..", $l1+4, "\n";

print "\n1) Test the CRC of a string variable\n";
$v1 = String::CRC32::crc32($string1);
print ($v1 == 1835534707 ? "ok 1\n" : "not ok 1\n");

print "\n2) Test the CRC of a string\n";
$v1 = String::CRC32::crc32("This is another test string");
print ($v1 == 2154698217 ? "ok 2\n" : "not ok 2\n");

$i = 2;

$l=$l1+3;
print "\n3..$l) Test the CRC of various substrings (using crcinit)\n";
for ($j = 0; $j <= $l1; $j++) {
  $v1 = String::CRC32::crc32(substr($string1, 0, $j));
  $v1 = String::CRC32::crc32(substr($string1, $j), $v1);
  $i++;
  print ($v1 == 1835534707 ? "ok $i\n" : "not ok $i\n");
}

$l=$l1+4;
print "\n$l) Test the CRC of a file\n";
$i++;
open(TESTFILE,"testfile") || 
  open(TESTFILE,"t/testfile") ||
  open(TESTFILE," ../testfile") || die "No such file!\n";
$v1 = String::CRC32::crc32(*TESTFILE);
close TESTFILE;
print ($v1 == 1925609391 ? "ok $i\n" : "not ok $i\n");

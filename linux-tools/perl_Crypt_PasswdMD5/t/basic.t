#
# Basic testing of the hashing function
#

use Crypt::PasswdMD5;

$phrase1 = "hello world\n";
$stage1 = '$1$1234$BhY1eAOOs7IED4HLA5T5o.';

$|=1;

print "1..6\n";

# Hashing of a simple phrase + salt
if (unix_md5_crypt($phrase1, "1234") eq $stage1) {
	print "ok 1\n";
}
else {
	print "not ok 1\n";
}

# Rehash (check) of the phrase
if (unix_md5_crypt($phrase1, $stage1) eq $stage1) {
	print "ok 2\n";
}
else {
	print "not ok 2\n";
}

# Hashing/rehashing of the empty password
$t = unix_md5_crypt('', $$);
if (unix_md5_crypt('', $t) eq $t) {
	print "ok 3\n";
}
else
{	
	print "not ok 3\n";
}

# Make sure null salt works
$t = unix_md5_crypt('test4');
($salt) = ($t =~ m/\$.+\$(.+)\$/);
if (unix_md5_crypt('test4',$salt) eq $t) {
	print "ok 4\n";
}
else
{
	print "not ok 4\n";
}
  
# and again with the Apache Variant
$t = apache_md5_crypt('test5');
($salt) = ($t =~ m/\$.+\$(.+)\$/);
if (apache_md5_crypt('test5',$salt) eq $t) {
        print "ok 5\n";
}
else
{
        print "not ok 5\n";
}
  
if ( $t =~ /^\$apr1\$/ ) {
        print "ok 6\n";
}
else
{
        print "not ok 6\n";
}

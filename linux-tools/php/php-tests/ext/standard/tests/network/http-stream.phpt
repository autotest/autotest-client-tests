--TEST--
http-stream test
--SKIPIF--
<?php
if (getenv("SKIP_SLOW_TESTS")) die("skip slow test");
if (getenv("SKIP_ONLINE_TESTS")) die("skip online test");
if (!extension_loaded("dom")) die("skip dom extension is not present");
?>
--INI--
allow_url_fopen=1
--FILE--
<?php
$d = new DomDocument;
$e = $d->load("http://test1.au.example.com/bug-118786.html");
echo "ALIVE\n";
?>
--EXPECTF--
ALIVE

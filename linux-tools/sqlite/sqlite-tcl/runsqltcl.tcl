#!/usr/bin/tclsh

	set arg0 [lindex $argv 0]

	load /usr/$arg0/tcl8.5/sqlite3/libtclsqlite3.so Sqlite3
	sqlite3 db sample2.db
	db eval {CREATE TABLE t1(a TEXT, b INTEGER)}
	db eval {
   		INSERT INTO t1 VALUES('one',1);
      		INSERT INTO t1 VALUES('two',2);
         	INSERT INTO t1 VALUES(NULL,3);
 	}
	puts [db eval {Select * From t1}]
	db eval {Drop Table t1}
	db close

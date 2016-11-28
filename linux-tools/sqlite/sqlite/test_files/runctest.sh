c_sqlite3 ctest.db "create table ct1 (t1key INTEGER PRIMARY KEY,data TEXT,num double)"
c_sqlite3 ctest.db "insert into ct1 (data,num) values ('This is c program sample data',3)"
c_sqlite3 ctest.db "insert into ct1 (data,num) values ('This is more c program sample data',6)"
c_sqlite3 ctest.db "select * from ct1"
rm ctest.db

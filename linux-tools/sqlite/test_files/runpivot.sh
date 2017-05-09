cd `dirname $0`
source $LTPBIN/tc_utils.source
sqlite3 examdatabase < examScript
sqlite3 examdatabase < examLOG
sqlite3 examdatabase2 < examScript
sqlite3 examdatabase2 < examLOG
sqlite3 examdatabase "insert into exam (ln,fn,exam,score)  values ('Anderson','Bob',1,75)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score)  values ('Anderson','Bob',2,80)"
sqlite3 examdatabase "update exam set score=82 where ln='Anderson' and fn='Bob' and exam=2"
sqlite3 examdatabase2 "insert into exam (ln,fn,exam,score) values ('Carter','Sue',1,89)"
sqlite3 examdatabase2 "insert into exam (ln,fn,exam,score) values ('Carter','Sue',2,100)" 
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Anderson','Bob',3,92)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Anderson','Bob',4,95)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Stoppard','Tom',1,88)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Stoppard','Tom',2,90)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Stoppard','Tom',3,92)"
sqlite3 examdatabase "insert into exam (ln,fn,exam,score) values ('Stoppard','Tom',4,95)"
sqlite3 examdatabase2 "insert into exam (ln,fn,exam,score) values ('Carter','Sue',3,99)"
sqlite3 examdatabase2 "insert into exam (ln,fn,exam,score) values ('Carter','Sue',4,95)"
sqlite3 < attach_pivot
rm examdatabase examdatabase2                

logfile = /var/log/vsm/archiver.log
interval = 2m
fs = Qfs2
        1  -norelease 2m
        2  -norelease 5m

params
allsets -startage 2m -startsize 10G -startcount 1000
Qfs2.1 -recycle_mingain 4 -recycle_minobs 50 -recycle_dataquantity 1G
Qfs2.2 -recycle_mingain 4 -recycle_minobs 50 -recycle_dataquantity 1G
endparams

vsns
Qfs2.1 dk diskar01
Qfs2.2 dk diskar02
endvsns

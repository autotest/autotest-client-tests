#!/bin/bash

set -ex

tdir="/home/nhenke/don-save/$(date +%s)"
mkdir -p $tdir

cd $tdir
samfsdump -f samfs2.dump /DKARC01
gzip -9 samfs2.dump
samfsdump -f samfs1.dump /sam1
gzip -9 samfs1.dump

samd umount
samd unload

cd /etc/opt/
tar zcvf $tdir/etc-$(date +%s).tar.gz vsm
cd /var/opt/
tar zcvf $tdir/var-$(date +%s).tar.gz vsm
cd /var/log/
tar zcvf $tdir/log-$(date +%s).tar.gz vsm

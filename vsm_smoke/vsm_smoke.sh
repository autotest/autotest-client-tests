#!/bin/sh

source ./fs_maker.sh

TAPFILE=./vsm_smoke.tap
TESTNUMB=0

MILESYS1='Qfs2'
FILESYS1='qfs2'
MILESYS2='Qfs3'
FILESYS2='qfs3'
MILESYS3='Qfs4'
FILESYS3='qfs4'

# mkfs opts for each filesys
SAMMKFS_OPTS[1]="-a 64"
SAMMKFS_OPTS[2]="-a 64"
SAMMKFS_OPTS[3]="-a 64"

umountfs0()
{
	samd stop
	samd stopsam
	samd stopsam
	fuser -ck $MILESYS1
        umount  $MILESYS1
	EXITEM=$?
        if [ $EXITEM != 0 ]
        then
		echo "umount FAILED"
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS1
        	umount  $MILESYS1
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo "Bail out! second umount of $MILESYS1 FAILED. " >> $TAPFILE
			echo " second umount FAILED"
                	exit 1
        	fi
        fi
	return 0
}

umountfs1()
{
	samd stop
	samd stopsam
	samd stopsam
	fuser -ck $MILESYS2
        umount  $MILESYS2
	EXITEM=$?
        if [ $EXITEM != 0 ]
        then
		echo "umount failed"
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS2
        	umount  $MILESYS2
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo "Bail out! second umount of $MILESYS2 FAILED. " >> $TAPFILE
			echo " second umount failed"
                	exit 1
        	fi
        fi
	return 0
}

umountfs2()
{
	samd stop
	samd stopsam
	samd stopsam
	fuser -ck $MILESYS3
        umount  $MILESYS3
	EXITEM=$?
        if [ $EXITEM != 0 ]
        then
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS3
        	umount  $MILESYS3
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo "Bail out! second umount of $MILESYS3 FAILED. " >> $TAPFILE
			echo " second umount FAILED"
                	exit 1
        	fi
        fi
	return 0
}

PostTestResult()
{
        TESTNUMB=`expr $TESTNUMB + 1`
        if [ $EXITEM != 0 ]
        then
                echo " Test failed."
                echo "not ok $TESTNUMB - $TESTNAME" >> $TAPFILE
        else
		echo " Test passed."
                echo "ok $TESTNUMB - $TESTNAME" >> $TAPFILE
        fi
}

check_exitem_for_crash()
{
  if [ $EXITEM != 0 ]
  then
       echo "Test failed trigger crash."
       echo "Bail out! Test failed trigger crash." >> $TAPFILE
       samtrace -V -f >/tmp/Sammy.$$
       sync
       #echo "c" > /proc/sysrq-trigger
       exit 1
  fi
}


sleep 10
SUITENAME1='SmokeOne'
TESTNAME1='Sammkfs'
TESTNAME2='MountFs'
TESTNAME3='BuildFiles'
TESTNAME4='ArchiveFiles1'
TESTNAME5='ArchiveFiles2'
TESTNAME6='ArchiveFiles3'
TESTNAME7='ArchiveFiles4'
TESTNAME8='ReleaseFiles1'
TESTNAME9='ReleaseFiles2'
TESTNAME10='ReleaseFiles3'
TESTNAME11='ReleaseFiles4'
TESTNAME12='ReleaseCheck1'
TESTNAME13='ReleaseCheck2'
TESTNAME14='ReleaseCheck3'
TESTNAME15='ReleaseCheck4'
TESTNAME16='SamfsDump'
TESTNAME17='ArchiverCPU'
TESTNAME18='ArfindCPU'
TESTNAME19='StageFiles1'
TESTNAME20='StageFiles2'
TESTNAME21='StageFiles3'
TESTNAME22='StageFiles4'
TESTNAME23='StagerCPU'
TESTNAME24='UmountFs1'
TESTNAME25='Samfsck1'
TESTNAME26='Sammkfs2'
TESTNAME27='MountFs2'
TESTNAME28='SamfsRestore'
TESTNAME29='StageFiles1'
TESTNAME30='StageFiles2'
TESTNAME31='StageFiles3'
TESTNAME32='StageFiles4'
TESTNAME33='UmountFs2'
TESTNAME34='Samfsck2'
TESTNAME35='Samfsck3'
TESTNAME36='Samfsck4'
BIN=`pwd`
BINDIR=`pwd`
SUITEDIR='/Harness'

rm -f $TAPFILE

echo "1..20" >> $TAPFILE

if test -f /usr/tmp/mountopts; then
  echo "Mount extras are in file mountopts. "
  Mounter=`cat /usr/tmp/mountopts`
  echo $Mounter
fi

date
$BINDIR/perl_umounter
sleep 10
$BINDIR/perl_umounter

if test -d /etc/opt/SAVER; then
  cp /etc/opt/SAVER/* /etc/opt/vsm/
  cp /etc/opt/SAVER/* /etc/opt/VSMsamfs/
fi

rm -f /etc/opt/vsm/archiver.cmd
rm -f /etc/opt/vsm/diskvols.conf

if test -d /etc/opt/VSMsamfs; then
  rm -f /etc/opt/VSMsamfs/archiver.cmd
  rm -f /etc/opt/VSMsamfs/diskvols.conf
fi

# XXX HORRRRRRIBLE
# mcf -> normal
# mcf_shared -> normal_shared
# etc until nausea
# cp $VSM_TEST_DIR/config/$HOST_CONFIG/mcf /etc/opt/vsm/mcf
# cp $VSM_TEST_DIR/config/$HOST_CONFIG/archiver.cmd /etc/opt/vsm/archiver.cmd
# cp $VSM_TEST_DIR/config/$HOST_CONFIG/diskvols.conf /etc/opt/vsm/diskvols.conf

echo " Now remove trace files. "

rm -rf /var/opt/vsm/trace/sam-archiv*
rm -rf /var/opt/vsm/trace/sam-recyc*
rm -rf /var/opt/vsm/trace/sam-stag*
rm -rf /var/opt/vsm/trace/sam-cat*
rm -rf /var/opt/vsm/trace/sam-fsd

if test -d /var/opt/VSMsamfs; then
  rm -rf /var/opt/VSMsamfs/trace/sam-archiv*
  rm -rf /var/opt/VSMsamfs/trace/sam-recyc*
  rm -rf /var/opt/VSMsamfs/trace/sam-stag*
  rm -rf /var/opt/VSMsamfs/trace/sam-cat*
  rm -rf /var/opt/VSMsamfs/trace/sam-fsd
fi

for f in $(\ls /var/log/vsm/*.log); do
    rm -fv $f
    touch $f
done

sleep 5
samd stop
samd config
sleep 5

# Do a sammkfs test first.

TESTNAME=$TESTNAME1
#Secsone=`$SUITEDIR/timesec`
sammkfs0
EXITEM=$?
PostTestResult

# Next do a mount test.

TESTNAME=$TESTNAME2
mountfs0
mkdir /$FILESYS2/sam_1
mkdir /$FILESYS3/sam_2
samd config
sleep 5

mountfs1
EXITEM=$?
PostTestResult
sleep 5


# create some files!
TESTNAME=$TESTNAME3
/opt/vsm/tools/mtf -g -s 1k-1G /$FILESYS1/One/file[0-9]
EXITEM=$?
PostTestResult

TESTNAME=$TESTNAME4
sleepcount=0
while true
do
        COUNT=`sfind /$FILESYS1/One/f* ! -copies 2 | wc -l`
        echo $COUNT
        if [ $COUNT != 0 ]
        then
                if [ $sleepcount -gt 6 ]; then
                    echo "Archiving taking too long.  Bailing."
		    echo "Bail out! archiving taking too long."
                    exit 1
                fi
                echo "Archiving to be done."
		date
                sleep 120
                sleepcount=`expr $sleepcount + 1`
        else
                echo "All archived."
                break
        fi
done
EXITEM=$?
PostTestResult

# Next do a release test.

TESTNAME=$TESTNAME8
release -r /$FILESYS1/One
EXITEM=$?
check_exitem_for_crash
PostTestResult


# Check files are released.

TESTNAME=$TESTNAME12
COUNT=`sfind /$FILESYS1/One/f* ! -offline | grep file | wc -l`
echo $COUNT
if [ $COUNT != 0 ]
then
        echo "File not offline."
	date
else
        echo "Files Are All offline."
        break
fi
EXITEM=$?
PostTestResult

# Now samfsdump the main file system.

TESTNAME=$TESTNAME16
samfsdump -f /$FILESYS2/Sammy /$FILESYS1/*
EXITEM=$?
PostTestResult

# Capture cpu time used by archiver.

#TESTNAME=$TESTNAME17
#TESTSPASSED=1
#TOTALTESTS=1
#TESTSRUN=1
#TESTSFAILED=0
#TESTSWARNINGS=0
#SecsTotal=`perl_time_archiver`
#$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

# Capture cpu time used by arfind.

#TESTNAME=$TESTNAME18
#TESTSPASSED=1
#TESTSRUN=1
#TESTSFAILED=0
#SecsTotal=`perl_time_arfind`
#$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

# Now stage the One files backin.

TESTNAME=$TESTNAME19
stage -r /$FILESYS1/One
EXITEM=$?
check_exitem_for_crash
PostTestResult

stage -w -r /$FILESYS1/One
TESTNAME=$TESTNAME19-w
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Capture cpu time used by stager.

TESTNAME=$TESTNAME23
#SecsTotal=`perl_time_stager`
#$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

# Time umount of fs.

TESTNAME=$TESTNAME24
umountfs0
EXITEM=$?
PostTestResult

# Time samfsck of fs.

TESTNAME=$TESTNAME25
samfsck -V $MILESYS1
EXITEM=$?
PostTestResult

# Do another sammkfs test.

TESTNAME=$TESTNAME26
sammkfs1
EXITEM=$?
PostTestResult

# Now mount the file system.

TESTNAME=$TESTNAME27
mountfs1
EXITEM=$?
PostTestResult

# Now samfsrestore the main file system.

TESTNAME=$TESTNAME28
samfsrestore -f /$FILESYS2/Sammy
EXITEM=$?
PostTestResult

# Now stage the One files backin.

TESTNAME=$TESTNAME29
stage -r /$FILESYS1/One
EXITEM=$?
check_exitem_for_crash
PostTestResult

TESTNAME=$TESTNAME29-w
stage -w -r /$FILESYS1/One
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Time umount of fs.

TESTNAME=$TESTNAME33
umountfs0
EXITEM=$?
PostTestResult

# Time samfsck of fs.

TESTNAME=$TESTNAME34
samfsck -V $MILESYS1
EXITEM=$?
PostTestResult

# Umount the other two file systems.

umountfs1
TESTNAME=$TESTNAME35
samfsck -V $MILESYS2
EXITEM=$?
PostTestResult

umountfs2
TESTNAME=$TESTNAME36
samfsck -V $MILESYS3
EXITEM=$?
PostTestResult

date

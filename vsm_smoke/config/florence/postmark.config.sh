#!/bin/sh
set -v

# XXX Needs to be passed in or determined by hostname
HOST_CONFIG="florence"

MILESYS1='Qfs2'
FILESYS1='qfs2'
MILESYS2='Qfs3'
FILESYS2='qfs3'
MILESYS3='Qfs4'
FILESYS3='qfs4'

LOG_DIR="/home/jenkins/tests/logs"

mkdir -p $LOG_DIR
mkdir -p /$FILESYS1
mkdir -p /$FILESYS2
mkdir -p /$FILESYS3

sammkfs1()
{
	pkill -HUP sam-fsd
	sleep 2
	sammkfs -a 64 $MILESYS1 </dev/null
	FXITEM=$?
	if [ $FXITEM != 0 ]
	then
		
		exit 1
	fi
	return 0
}

sammkfs0()
{
	pkill -HUP sam-fsd
	sleep 2
	sammkfs -a 64 $MILESYS1 </dev/null
	FXITEM=$?
	if [ $FXITEM != 0 ]
	then
		echo " sammkfs one failed. "
		exit 1
	fi
	sammkfs -a 64 $MILESYS2 </dev/null
	FXITEM=$?
	if [ $FXITEM != 0 ]
	then
		echo " sammkfs two failed. "
		exit 1
	fi
	sammkfs -a 64 $MILESYS3 </dev/null
	FXITEM=$?
	if [ $FXITEM != 0 ]
	then
		echo " sammkfs three failed. "
		exit 1
	fi
	return 0
}

mountfs0()
{
        mount -t samfs -o stripe=0,nosam$Mounter $MILESYS2 /$FILESYS2
        if [ $? != 0 ]
        then
                echo " sammfs mount test 0 FAILED. "
		sleep 2
        	mount -t samfs -o stripe=0,nosam$Mounter $MILESYS2 /$FILESYS2
        	if [ $? != 0 ]
        	then
                	echo " second sammfs mount test 1 FAILED. "
                	exit 1
        	fi
        fi
	echo "Second file system mounted. "
	sleep 10
        mount -t samfs -o stripe=0,nosam$Mounter $MILESYS3 /$FILESYS3
        if [ $? != 0 ]
        then
                echo " sammfs mount test 0 FAILED. "
		sleep 2
        	mount -t samfs -o stripe=0,nosam$Mounter $MILESYS3 /$FILESYS3
        	if [ $? != 0 ]
        	then
                	echo " second sammfs mount test 2 FAILED. "
                	exit 1
        	fi
        fi
	echo "Third file system mounted. "
	sleep 10
	return 0
}

mountfs1()
{
        mount -t samfs -o stripe=0,sam$Mounter $MILESYS1 /$FILESYS1
        if [ $? != 0 ]
        then
                echo " sammfs mount test 0 FAILED. "
		sleep 2
        	mount -t samfs -o stripe=0,sam$Mounter $MILESYS1 /$FILESYS1
        	if [ $? != 0 ]
        	then
                	echo " second sammfs mount test 0 FAILED. "
                	exit 1
        	fi
        fi
	echo "First file system mounted. "
	return 0
}

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
                echo " umount FAILED. "
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS1
        	umount  $MILESYS1
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo " second umount FAILED. "
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
                echo " umount FAILED. "
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS2
        	umount  $MILESYS2
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo " second umount FAILED. "
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
                echo " umount FAILED. "
		sleep 10
		samd stop
		samd stopsam
		samd stopsam
		fuser -ck $MILESYS3
        	umount  $MILESYS3
		EXITEM=$?
        	if [ $EXITEM != 0 ]
        	then
                	echo " second umount FAILED. "
                	exit 1
        	fi
        fi
	return 0
}

PostTestResult()
{
        if [ $EXITEM != 0 ]
        then
                echo " Test failed. "
                TESTSPASSED=0
                TESTSFAILED=1
        else
                TESTSPASSED=1
                TESTSFAILED=0
        fi
        TESTSRUN=1
        TESTNUMB=-1
        TOTALTESTS=1
        TESTWARNINGS=0
        Secstwo=`$SUITEDIR/timesec`
        SecsTotal=`expr $Secstwo - $Secsone`
	echo $SecsTotal
        $SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0
        TESTSPASSED=0
        TESTSFAILED=0
        TESTSRUN=0
        Secsone=`$SUITEDIR/timesec`
}

check_exitem_for_crash()
{
  if [ $EXITEM != 0 ]
  then
       echo "Test failed trigger crash. "
       samtrace -V -f >/tmp/Sammy.$$
       sync
       #echo "c" > /proc/sysrq-trigger
       exit 1
  fi
}


sleep 10
SUITENAME1='Postmark_One'
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
TESTSFAILED=0
TESTSPASSED=0
BIN=`pwd`
BINDIR='/home/ddk/bin'
SUITEDIR='/Harness'

echo "Mount extras are in file mountopts. "
Mounter=`cat /usr/tmp/mountopts`
echo $Mounter
date
$BINDIR/perl_umounter
sleep 10
$BINDIR/perl_umounter

cp /etc/opt/SAVER/* /etc/opt/vsm/
cp /etc/opt/SAVER/* /etc/opt/VSMsamfs/

rm /etc/opt/vsm/archiver.cmd
rm /etc/opt/vsm/diskvols.conf

rm /etc/opt/VSMsamfs/archiver.cmd
rm /etc/opt/VSMsamfs/diskvols.conf

cp $HOST_CONFIG/mcf /etc/opt/vsm/mcf
cp $HOST_CONFIG/archiver.cmd /etc/opt/vsm/archiver.cmd
cp $HOST_CONFIG/diskvols.conf /etc/opt/vsm/diskvols.conf

#cp $HOST_CONFIG/archiver.cmd /etc/opt/VSMsamfs/archiver.cmd
#cp $HOST_CONFIG/diskvols.conf /etc/opt/VSMsamfs/diskvols.conf

echo " Now remove trace files. "

rm -rf /var/opt/vsm/trace/sam-archiv*
rm -rf /var/opt/vsm/trace/sam-recyc*
rm -rf /var/opt/vsm/trace/sam-stag*
rm -rf /var/opt/vsm/trace/sam-cat*
rm -rf /var/opt/vsm/trace/sam-fsd

rm -rf /var/opt/VSMsamfs/trace/sam-archiv*
rm -rf /var/opt/VSMsamfs/trace/sam-recyc*
rm -rf /var/opt/VSMsamfs/trace/sam-stag*
rm -rf /var/opt/VSMsamfs/trace/sam-cat*
rm -rf /var/opt/VSMsamfs/trace/sam-fsd

rm -f $LOG_DIR/$FILESYS1/logs
touch $LOG_DIR/$FILESYS1/logs

for f in $(\ls /var/log/vsm/*.log); do
    rm -fv $f
    touch $f
done

$SUITEDIR/Suite_Start $SUITENAME1
sleep 5
samd stop
samd config
sleep 5

# Do a sammkfs test first.

TESTNAME=$TESTNAME1
Secsone=`$SUITEDIR/timesec`
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

#  perl_waiter

# Create many files to archive with postmarks.

TESTNAME=$TESTNAME3
perl_postmark_four
EXITEM=$?
PostTestResult


# Next wait for files to be archived, indicated by showque showing none waiting.

perl_showqueue

TESTNAME=$TESTNAME4
while true
do
        COUNT=`sfind /$FILESYS1/One/s*/. ! -copies 2 | wc -l`
        echo $COUNT
        if [ $COUNT != 8 ]
        then
                echo "Archiving to be done."
		date
                sleep 120
		date
                sleep 120
        else
                echo "All archived."
                break
        fi
done
EXITEM=$?
PostTestResult

# Next wait for files to be archived.

TESTNAME=$TESTNAME5
while true
do
        COUNT=`sfind /$FILESYS1/Two/s*/. ! -copies 2 | wc -l`
        echo $COUNT
        if [ $COUNT != 8 ]
        then
                echo "Archiving to be done."
		date
                sleep 120
		date
                sleep 120
        else
                echo "All archived."
                break
        fi
done
EXITEM=$?
PostTestResult

# Next wait for files to be archived.

TESTNAME=$TESTNAME6
while true
do
        COUNT=`sfind /$FILESYS1/Three/s*/. ! -copies 2 | wc -l`
        echo $COUNT
        if [ $COUNT != 8 ]
        then
                echo "Archiving to be done."
		date
                sleep 120
		date
                sleep 120
        else
                echo "All archived."
                break
        fi
done
EXITEM=$?
PostTestResult

# Next wait for files to be archived.

TESTNAME=$TESTNAME7
while true
do
        COUNT=`sfind /$FILESYS1/Four/s*/. ! -copies 2 | wc -l`
        echo $COUNT
        if [ $COUNT != 8 ]
        then
                echo "Archiving to be done."
		date
                sleep 120
		date
                sleep 120
        else
                echo "All archived."
                break
        fi
done
EXITEM=$?
PostTestResult

# Next do a release test.

TESTNAME=$TESTNAME8
release -r /$FILESYS1/One/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult


# Next do a release test.

TESTNAME=$TESTNAME9
release -r /$FILESYS1/Two/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult


# Next do a release test.

TESTNAME=$TESTNAME10
release -r /$FILESYS1/Three/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult


# Next do a release test.

TESTNAME=$TESTNAME11
release -r /$FILESYS1/Four/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Check files are released.

TESTNAME=$TESTNAME12
COUNT=`sfind /$FILESYS1/One/s*/. ! -offline | grep file | wc -l`
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

# Check files are released.

TESTNAME=$TESTNAME13
COUNT=`sfind /$FILESYS1/Two/s*/. ! -offline | grep file | wc -l`
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

# Check files are released.

TESTNAME=$TESTNAME14
COUNT=`sfind /$FILESYS1/Three/s*/. ! -offline | grep file | wc -l`
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

# Check files are released.

TESTNAME=$TESTNAME15
COUNT=`sfind /$FILESYS1/Four/s*/. ! -offline | grep file | wc -l`
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

TESTNAME=$TESTNAME17
TESTSPASSED=1
TOTALTESTS=1
TESTSRUN=1
TESTSFAILED=0
TESTSWARNINGS=0
SecsTotal=`$BIN/perl_time_archiver`
$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

# Capture cpu time used by arfind.

TESTNAME=$TESTNAME18
TESTSPASSED=1
TESTSRUN=1
TESTSFAILED=0
SecsTotal=`$BIN/perl_time_arfind`
$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

# Now stage the One files backin.

TESTNAME=$TESTNAME19
stage -r /$FILESYS1/One/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/One/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Two files backin.

TESTNAME=$TESTNAME20
stage -r /$FILESYS1/Two/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Two/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Three files backin.

TESTNAME=$TESTNAME21
stage -r /$FILESYS1/Three/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Three/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Four files backin.

TESTNAME=$TESTNAME22
stage -r /$FILESYS1/Four/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Four/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Capture cpu time used by stager.

TESTNAME=$TESTNAME23
TESTSPASSED=1
TESTSRUN=1
TESTSFAILED=0
SecsTotal=`$BIN/perl_time_stager`
$SUITEDIR/Post_Result $SUITENAME1 $TESTNAME $TESTNUMB $TOTALTESTS $TESTSRUN $TESTSPASSED $TESTSFAILED $TESTWARNINGS $SecsTotal 0

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
stage -r /$FILESYS1/One/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/One/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Two files backin.

TESTNAME=$TESTNAME30
stage -r /$FILESYS1/Two/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Two/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Three files backin.

TESTNAME=$TESTNAME31
stage -r /$FILESYS1/Three/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Three/s*/*
EXITEM=$?
check_exitem_for_crash
PostTestResult

# Now stage the Four files backin.

TESTNAME=$TESTNAME32
stage -r /$FILESYS1/Four/s*/*
EXITEM=$?
check_exitem_for_crash

stage -w -r /$FILESYS1/Four/s*/*
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

$SUITEDIR/Suite_Stop $SUITENAME1

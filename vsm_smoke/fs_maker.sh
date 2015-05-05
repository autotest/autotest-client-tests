#!/bin/sh
#set -v

if [ -z "$VSM_TEST_DIR" ]; then
    echo "You must include fs_config.sh, not $0 directly"
    exit 1
fi

# optional configuration items to be set from tests
# mkfs opts for each filesys
SAMMKFS_OPTS[1]=""
SAMMKFS_OPTS[2]=""
SAMMKFS_OPTS[3]=""
SAMMKFS_OPTS[4]=""
SAMMKFS_OPTS[5]=""

# mount options
SAMMOUNT_OPTS[1]="stripe=0,sam"
SAMMOUNT_OPTS[2]="stripe=0,nosam"
SAMMOUNT_OPTS[3]="stripe=0,nosam"
SAMMOUNT_OPTS[4]="stripe=0,nosam"
SAMMOUNT_OPTS[5]="stripe=0,nosam"

# fsck opts for each filesys
SAMFSCK_OPTS[1]=""
SAMFSCK_OPTS[2]=""
SAMFSCK_OPTS[3]=""
SAMFSCK_OPTS[4]=""
SAMFSCK_OPTS[5]=""

if test -f /usr/tmp/mountopts; then
    SAMMOUNT_OPTS_GLOBAL="$(cat /usr/tmp/mountopts)"
    echo "Global mount options: $SAMMOUNT_OPTS_GLOBAL"
fi

# define these in your tests to choose which ones to use
#
# These are the filesystem names and mount points that are synchronized into
# the mcf and archiver.cmd files for each platform, changing them is painful :-)
# MILESYS1='Qfs2'
# FILESYS1='qfs2'
# MILESYS2='Qfs3'
# FILESYS2='qfs3'
# MILESYS3='Qfs4'
# FILESYS3='qfs4'
# MILESYS4='Qfs5'
# FILESYS4='qfs5'

# bump if needing larger
MAX_FS_IDX=3

sammkfs0()
{
        pkill -HUP sam-fsd
        sleep 2

        for fs_idx in $(seq 1 $MAX_FS_IDX); do
            local fs="MILESYS${fs_idx}"
            local fsname="${!fs}"

            if [ -z "$fsname" ]; then
                echo "Skipping filesystem # $fs_idx, no name defined"
                continue
            fi
            cmd="sammkfs ${SAMMKFS_OPTS[$fs_idx]} $fsname"
            echo "Running sammkfs: $cmd"
            $cmd < /dev/null
            FXITEM=$?
            if [ $FXITEM != 0 ]
            then
                    echo " sammkfs # $fs_idx failed."
                    exit 1
            fi
        done
        return 0
}

sammkfs1()
{
        pkill -HUP sam-fsd
        sleep 2
        sammkfs ${SAMMKFS_OPTS[1]} $MILESYS1 </dev/null
        FXITEM=$?
        if [ $FXITEM != 0 ]
        then
                echo " sammkfs one failed. "
                exit 1
        fi
        return 0
}

mount_one()
{
    local fs_idx=$1

    local opts=${SAMMOUNT_OPTS[$fs_idx]}
    if [ -n "$SAMMOUNT_OPTS_GLOBAL" ]; then
        opts="$opts,$SAMMOUNT_OPTS_GLOBAL"
    fi

    local mntopt=""
    if [ -n "$opts" ]; then
        mntopt="-o $opts"
    fi

    local fs="MILESYS${fs_idx}"
    local fs_dir="FILESYS${fs_idx}"
    local fsname=${!fs}
    local fs_mnt=${!fs_dir}

    mkdir -p /$fs_mnt

    local rc=0
    for attempt in 0 1; do
        mount -t samfs $mntopt $fsname /$fs_mnt
        if [ $? == 0 ]; then
            echo "filesystem $fs_idx mounted"
            return 0
        else
            echo " sammfs mount test $fs_idx FAILED, attempt # $attempt. "
            sleep 2
        fi
    done
    echo "FAILED to mount fs $fsname"
    exit 1
}

mountfs0()
{
        for fs_idx in $(seq 2 $MAX_FS_IDX); do
            local fs="MILESYS${fs_idx}"
            local fsname="${!fs}"

            if [ -z "$fsname" ]; then
                echo "Skipping filesystem # $fs_idx, no name defined"
                continue
            fi

            mount_one $fs_idx
        done
        return 0
}

mountfs1()
{
        mount_one 1
        return 0
}

mountfsall()
{
    for fs_idx in $(seq 1 $MAX_FS_IDX); do
        local fs="MILESYS${fs_idx}"
        local fsname="${!fs}"

        if [ -z "$fsname" ]; then
            echo "Skipping filesystem # $fs_idx, no name defined"
            continue
        fi

        mount_one $fs_idx
    done
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

#!/bin/bash

#
# Run fsck and report errors back to the framework
#
test_samfsck() {
    fs=$1

    # Use IDX and Options ?
    # pass options directly ?

    samfsck -V $fs
    EXITEM=$?

    TESTWARNINGS=0
    if [ $EXITEM == 4 ]; then
        echo " A samfsck 4 warning. "
        TESTWARNINGS=1
        EXITEM=0
    elif [ $EXITEM == 5 ]; then
        echo " A samfsck 5 warning. "
        TESTWARNINGS=1
        EXITEM=0
    elif [ $EXITEM == 10 ]; then
        echo " A samfsck 10 warning. "
        TESTWARNINGS=1
        EXITEM=0
    else
        echo " A samfsck fatal error: $EXITEM"
    fi

    # no need to return value, EXITEM is set
}

#!/bin/bash

# variables for testsing

VSM_TEST_DIR=`pwd`

if ! test -f $VSM_TEST_DIR/config/test_config; then
    echo "no test_config in $VSM_TEST_DIR/lib/config"
    exit 1
fi

TEST_CONFIG=$VSM_TEST_DIR/config/$(cat $VSM_TEST_DIR/config/test_config)

if ! test -f $TEST_CONFIG; then
    echo "Bad TEST_CONFIG '$TEST_CONFIG'"
    exit 1
fi

# config parsing 
# from http://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml $TEST_CONFIG)

# check output of config yaml
if [ -z "$HOST_CONFIG" ]; then
    echo "bad HOST_CONFIG in $TEST_CONFIG"
    cat $TEST_CONFIG
    exit 1
fi

if [ -z "$DISK_CONFIG" ]; then
    echo "bad DISK_CONFIG in $TEST_CONFIG"
    cat $TEST_CONFIG
        exit 1
fi

#OUTDIR=`pwd`
# setup defaults for LOG_DIR
#if [ -z "$OUTDIR" ]; then
#    echo "OUTDIR is not set"
#    exit 1
#fi
#export LOG_DIR=${LOG_DIR:-"$OUTDIR/logs"}
#echo "Setting up LOG_DIR=$LOG_DIR"
#mkdir -p $LOG_DIR

# include our library
. $VSM_TEST_DIR/fs_maker.sh
. $VSM_TEST_DIR/samfsck.sh

echo "Running from $VSM_TEST_DIR for config $HOST_CONFIG..."

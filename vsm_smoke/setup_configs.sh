#!/bin/bash

#set -x

source ./fs_config.sh

c_dir=$VSM_TEST_DIR/lib/config
cd $c_dir/$HOST_CONFIG

for t in "build_hosts.sh"; do
  test -f $t && bash -x $t
done

cd $VSM_TEST_DIR/lib

disk_config_f=$c_dir/$HOST_CONFIG/$DISK_CONFIG

if ! test -f $disk_config_f; then
  echo "cannot find disk config '$DISK_CONFIG' for host config '$HOST_CONFIG'"
  exit 1
fi

python build_disk_partitions_and_configs.py $disk_config_f
rc=$?

if [ $rc -ne 0 ]; then
    echo "faild to build configs for $disk_config_f: $rc"
    exit $rc
fi

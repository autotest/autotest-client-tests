#!/bin/bash
set -ex

# setup shared configs

mdc0_hostname=$(hostname)
mdc0_ip=$(host $mdc0_hostname | awk '{print $NF'})

echo "$mdc0_hostname    $mdc0_ip    1    0    server" > hosts.Qfs2

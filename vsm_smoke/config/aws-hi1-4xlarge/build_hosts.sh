#!/bin/bash

# setup shared configs

mdc0_hostname=$(hostname)
mdc0_ip=$(hostname | cut -c 4- |  tr '-' '.')

echo "$mdc0_hostname    $mdc0_ip    1    0    server" > hosts.Qfs2

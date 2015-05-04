#!/bin/bash

export PATH=$PATH:/sbin

WT=2

mypt="parted -s -a optimal /dev/sdb"

$mypt mklabel gpt
$mypt print
$mypt mkpart primary 1MB 128GB
$mypt mkpart primary 128GB 256GB
$mypt print

mypt="parted -s -a optimal /dev/sde"

$mypt mklabel gpt
$mypt print
$mypt mkpart primary 1MB 2T
sleep $WT
$mypt mkpart primary 2T 4T
sleep $WT
$mypt mkpart primary 4T 6T
sleep $WT
$mypt mkpart primary 6T 8T
sleep $WT
$mypt print

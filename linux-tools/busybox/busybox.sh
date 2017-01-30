#!/bin/bash
# vi: ts=4 sw=4 expandtab:
############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##      1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##      2.Redistributions in binary form must reproduce the above copyright notice, this  ##
##        list of conditions and the following disclaimer in the documentation and/or     ##
##        other materials provided with the distribution.                                 ##
##                                                                                        ##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
############################################################################################
#
# File :    busybox.sh
#
# Description:  Test the functions provided by busybox.
#
# Author:   Robert Paulsen, rpaulsen@us.ibm.com
#
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/busybox
source $LTPBIN/tc_utils.source
BB_DIR=${LTPBIN%/shared}/busybox

################################################################################
# global variables
################################################################################

names="" # busybox commands to be tested
MyDIR=${LTPBIN%/shared}/busybox	
thisfilename=${0##*/}
fullfilename=$0

declare -i untested=0
declare -i unsupported=0
declare -i insufficient=0
declare -i unknown=0

IFACE=""
ROUTER=""

IPV6=""
restart_xinetd=""

MY_LOOP_DEVS=""

################################################################################
# local utility functions
################################################################################

#
# setup
#
function tc_local_setup()
{   
    [ "localhost.localdomain" = "$(hostname)" ] &&  hostname localhost
 
    tc_get_os_ver && tc_get_os_arch
    tc_break_if_bad $? "cannot get OS version or architecture" || return

    local xxx=$(route -n | grep "^0.0.0.0")
    [ "$xxx" ] && set $xxx && IFACE=$8
    [ "$IFACE" ]
    tc_break_if_bad $? "can't find network interface" || return

    xxx=$(route -n | grep "^0.0.0.0 .*UG.*$IFACE$")
    [ "$xxx" ] && set $xxx && ROUTER=$2
    [ "$ROUTER" ]
    tc_break_if_bad $? "can't find router" || return

    tc_ipv6_info && IPV6=yes

    [ -f /etc/inetd.conf ] && mv /etc/inetd.conf $TCTMP

    FAILS=""
    return 0
}

#
# cleanup
#
function tc_local_cleanup()
{
    [ "$OLD_FREQ" ] &&
    busybox adjtimex -f $OLD_FREQ &>/dev/null
    [ "$OLD_TICK" ] &&
    busybox adjtimex -t $OLD_TICK &>/dev/null

    [ "$BRIDGE0" ] &&busybox brctl delbr $BRIDGE0
    [ "$BRIDGE1" ] &&busybox brctl delbr $BRIDGE1

    local rc=$?
    killall busybox &>/dev/null
    [ -f $TCTMP/hosts ] && mv $TCTMP/hosts /etc/hosts
    [ -f $TCTMP/telnet ] && mv $TCTMP/telnet /etc/xinetd.d/telnet
    [ -f $TCTMP/inetd.conf ] && mv $TCTMP/inetd.conf /etc/inetd.conf
    /etc/init.d/xinetd stop &>/dev/null
    [ "$restart_xinetd" = "yes" ] && /etc/init.d/xinetd start &>/dev/null

    local my_loop_dev=$(cat /proc/mounts | grep $TCTMP/bb_mnt)
    [ "$my_loop_dev" ] && set $my_loop_dev && my_loop_dev=$1
    busybox umount $TCTMP/bb_mnt &>/dev/null
    [ "$my_loop_dev" ] && losetup -d $my_loop_dev

    local fail_count=0 brok_count=0
    [ "$TC_FAILS" ] && set $TC_FAILS && fail_count=$#
    [ "$TC_BROKS" ] && set $TC_BROKS && brok_count=$#

    (( TESTED=TST_TOTAL-unsupported-unknown-untested-insufficient ))
    tc_info "============ Summary ======================"
    tc_info "$((TST_TOTAL-1)) total applets"
    tc_info "$unsupported unimplemented test(s)"
    tc_info "$untested declined test(s)"
    [ $insufficient -ne 0 ] &&
    tc_info "$insufficient test(s) with insufficient system resources"
    [ $unknown -ne 0 ] &&
    tc_info "$unknown unrecognized busybox utilities"
    tc_info "$((TESTED-1)) applets actually tested"
    ((fail_count)) && tc_info "$fail_count FAILs $TC_FAILS"
    ((brok_count)) && tc_info "$brok_count BROKs $TC_BROKS"
    tc_info "==========================================="
    TST_TOTAL=$TESTED
}

################################################################################
# the testcase functions
################################################################################

function installation_check()
{
    tc_register "installation check"
    tc_executes busybox
    tc_fail_if_bad $? "busybox not properly installed" || return

    tc_pass_or_fail 0       # pass if we get this far
}

function do_LBR()
{
    tc_exec_or_break grep || return
    busybox [ 2>&1 | grep "\[: missing" >/dev/null
    tc_pass_or_fail $?
}

function do_LBR_LBR()
{
    busybox [[ -d $TCTMP ]]
    tc_pass_or_fail $? "expected \"[[ -d $TCTMP ]]\" to return true"
}

function do_addgroup()
{
    busybox addgroup group$$ >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from busybox addgroup group$$" || return

    grep group$$ /etc/group >$stdout 2>$stderr
    tc_fail_if_bad $? "group group$$ did not show up in /etc/groups" || return

    busybox delgroup group$$ >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from busybox delgroup group$$" || return

    ! grep group$$ /etc/group >$stdout 2>$stderr
    tc_pass_or_fail $? "group group$$ was not deleted from in /etc/groups"
}

function do_delgroup()
{
    do_addgroup $1
}

function do_adjtimex()
{

    tc_root_or_break || return

    busybox adjtimex >$stdout 2>>$stderr
    tc_fail_if_bad $?  "unexpected response from \"busybox adjtimex\"" || return
    grep -q timeconstant $stdout
    tc_fail_if_bad $?  "expected to see \"timeconstant\" in stdout" || return

    # Check if supporting utilities are available
    tc_exec_or_break awk || return

    unset OLD_TICK
    unset OLD_FREQ
    OLD_TICK=`busybox adjtimex | awk '/tick/{print $3}'`
    OLD_FREQ=`busybox adjtimex | awk '/freq.adjust/{print $3}'`
    [ "$OLD_TICK" ] && [ "$OLD_FREQ" ]
    tc_fail_if_bad $? "\"busybox adjtimex\" could not read tic and frequency" || return

    busybox adjtimex -f -1234567 >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \"busybox adjtimex -f -1234567\"" || return
    grep -q "\-1234567" $stdout
    tc_fail_if_bad $?  "expected to see \"\-1234567\" in stdout" || return

    local tic_amt=9999
    uname -m | grep -q "ia64" && tic_amt=999
    busybox adjtimex -t $tic_amt >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \"busybox adjtimex -t $tic_amt\"" || return
    busybox adjtimex | grep "$tic_amt" >& $stdout

    # Reset tick and freq back to their original values
    busybox adjtimex -f $OLD_FREQ -t $OLD_TICK >& $stdout
    tc_pass_or_fail $? "unexpected response from \"busybox adjtimex -f $OLD_FREQ -t $OLD_TICK\"" || return
    unset OLD_TICK
    unset OLD_FREQ
}

function do_adduser()
{
    busybox adduser -D user$$ >$stdout 2>$stderr
    tc_fail_if_bad $? "could not add user without password" || return
	
    grep user$$ /etc/passwd >$stdout 2>$stderr
    tc_fail_if_bad $? "user user$$ did not show up in /etc/passwd" || return

    busybox deluser user$$ >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from busybox deluser user$$" || return

    rm -rf /home/user$$ >$stdout 2>$stderr
    tc_fail_if_bad $? "Could not delete /home/user$$" || return

    ! grep user$$ /etc/passwd >$stdout 2>$stderr
    tc_pass_or_fail $? "user user$$ was not deleted from in /etc/passwd"
}

function do_deluser()
{
    do_adduser $1
}

function do_ar()
{
    (
    cd $TCTMP

    # files to put in archive
cat <<EOF >expected1
This is ar_file1.txt
It has two lines.
EOF
cat <<EOF > expected2
This is ar_file2.txt
It has
three lines.
EOF

    # expected data for stdout
cat <<EOF >expected
$(<expected1)
$(<expected2)
EOF

    # ocreate the archive
cat <<EOF >busybox.ar
!<arch>
ar_file1.txt/   1253815796  0     0     100644  39        \`
$(<expected1)

ar_file2.txt/   1253815849  0     0     100644  41        \`
$(<expected2)

EOF

    # list contents
    local cmd="busybox ar -t busybox.ar"
    tc_info "testing command \"$cmd\""
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    tc_executes grep && {
        grep -q ar_file1.txt $stdout && grep -q ar_file2.txt $stdout
        tc_fail_if_bad $? "ar_file1.txt and/or ar_file2.txt nt listed in stdout" || return
    }

    # extract to stdout
    local cmd="busybox ar -p busybox.ar"
    tc_info "testing command \"$cmd\""
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    tc_executes diff && {
        cp $stdout actual
        diff actual expected >$stdout 2>$stderr
        tc_fail_if_bad $? "miscompare" || return
    }

    # extract to files
    local cmd="busybox ar -x -o busybox.ar ar_file1.txt ar_file2.txt"
    tc_info "testing command \"$cmd\""
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    tc_executes diff && {
        diff expected1 ar_file1.txt >$stdout 2>$stderr
        tc_fail_if_bad $? "miscompare for file ar_file1.txt" || return
        diff expected2 ar_file2.txt >$stdout 2>$stderr
        tc_fail_if_bad $? "miscompare for file ar_file2.txt" || return
    }
    )
    tc_pass
}

function do_ash()
{
    [ "`echo exit | (busybox ash; echo $_ ) 2>$stderr`" = "ash" ] 
    tc_pass_or_fail $?  "unexpected output"
}

function do_arp()
{
    tc_get_os_arch
    [ "$TC_OS_ARCH" = "s390x" ] && do_insufficient $1 "not supported on s390x -- use qetharp instead. qetharp tested by s390-tools." && return

    ping -c 2 -w 5 $ROUTER &>/dev/null

    busybox arp -n >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from busybox arp" || return

    grep -q $ROUTER $stdout
    tc_pass_or_fail $? "no info for $ROUTER in arp table"
}

function do_arping()
{
    tc_get_os_arch
    [ "$TC_OS_ARCH" = "s390x" ] && do_insufficient $1 "not supported on s390x." && return

    tc_get_iface
    tc_break_if_bad $? "Could not find network interface" || return
    local cmd="busybox arping -c 1 -I $TC_IFACE $ROUTER"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    local expected="reply from $ROUTER"
    grep -q "$expected" $stdout
    tc_pass_or_fail $? "expected to see \"$expected\" in stdout"
}

function do_awk()
{

    # create input data
cat <<-EOF > $TCTMP/awkdata
123|Jones|123 4th Street|555-1212|100.00
234|Smith|234 5th Ave|234-9876|59.65
345|Baker|345 6th St|987-3456|37.45
456|Smith|456 7th Avenue|538-6574|00.27
EOF

    # create awk script
cat <<-EOF > $TCTMP/awkpgm
END     { printf "TOTAL is %.2f\n", total }
BEGIN   { FS="|"
          total = 0.0
          printf "Report for %s\n", name
        }
\$2 == name {
          total += \$5
          print \$0
        }
EOF

    # create expected output data
cat <<-EOF > $TCTMP/expected
Report for Smith
234|Smith|234 5th Ave|234-9876|59.65
456|Smith|456 7th Avenue|538-6574|00.27
TOTAL is 59.92
EOF

    busybox awk -v name=Smith -f $TCTMP/awkpgm $TCTMP/awkdata >$stdout 2>$stderr
    tc_fail_if_bad $? "Unexpected response from \"busybox awk -f $TCTMP/awkpgm $TCTMP/awkdata\"" || return

    diff "$TCTMP/expected" $stdout 2>$stderr
    tc_pass_or_fail $? "Expected to see the following in stdout:" \
    "$(echo =============================================; cat $TCTMP/expected)" \
    "============================================="
}

function do_basename()
{
    local actual="`busybox basename $0 2>$stderr`"
    [ "$actual" = "${0##*/}" ]
    tc_pass_or_fail $? "unexpected output" \
        "expected \"$thisfilename\", got \"$actual\""
}

function do_brctl()
{
    tc_get_os_arch	# sets TC_OS_ARCH
    local sys_arch=$(uname -m)

# see bug 64374, comment #3
#    ((BBOX_VER<=11500)) && [ "$TC_OS_ARCH" != "$sys_arch" ] && {
#        do_insufficient $1 "busybox version $BBOX_VER's use of ioctl not supported on mixed 32/64 arch: $TC_OS_ARCH on $sys_arch"
#        return 0
#    }

    tc_info "Busybox version $BBOX_VER testing OS arch $TC_OS_ARCH on $sys_arch hardware/kernel"

    tc_get_iface
    tc_break_if_bad $? "could not find ethernet interface" || return
    local br_iface=$TC_IFACE

    # These globals will be used in tc_local_cleanup to undo anything left half done
    BRIDGE0=bridge0
    BRIDGE1=bridge1

    local showcmd="busybox brctl show"

    local cmd0="busybox brctl addbr $BRIDGE0"
    local cmd1="busybox brctl addbr $BRIDGE1"
    tc_info "testing \"$cmd0\""
    tc_info "testing \"$cmd1\""
    $cmd0 >$stdout 2>$stderr &&
    $cmd1 >$stdout 2>$stderr
    tc_fail_if_bad $? "Could not add bridge" || return

    tc_info "testing \"$showcmd\""
    $showcmd >$stdout 2>$stderr
    tc_fail_if_bad $? "Could not show bridges" || return
    grep -q $BRIDGE0 $stdout && grep -q $BRIDGE1 $stdout
    tc_fail_if_bad $? "bridge names did not show" || return

    cmd="busybox brctl stp $BRIDGE1 1"
    tc_info "testing \"$cmd\""
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "could not set STP" || return
    $showcmd >$stdout 2>$stderr
    grep -iq "$BRIDGE1.*yes" $stdout
    tc_fail_if_bad $? "Could not show STP set" || return

#
# For some reason the addif/delif commands work OK when run by hand but they
# fail in this script. Failure is a hang that requires Ctrl-C to break out of.
# That needs to be done from a local console, not from an ssh networked session.
#
# I note that the "real" brctl shows the same behavior and that the testcase for
# that also conveniently skips addif/delif testing!
#
#    cmd="busybox brctl addif $BRIDGE0 $br_iface"
#    tc_info "testing \"$cmd\""
#    $cmd >$stdout 2>$stderr
#    tc_fail_if_bad $? "Could not add interface" || return
#    $showcmd >$stdout 2>$stderr
#    grep -q "$BRIDGE0.*$br_iface" $stdout
#    tc_fail_if_bad $? "could not show interface" || return
#
#    cmd="busybox brctl delif x$BRIDGE0 $br_iface"
#    tc_info "testing \"$cmd\""
#    $cmd >$stdout 2>$stderr
#    tc_fail_if_bad $? "Could not delete interface" || return
#    $showcmd >$stdout 2>$stderr
#    ! grep -q "$BRIDGE0.*$br_iface" $stdout
#    tc_fail_if_bad $? "could not show that interface was deleted" || return

    cmd0="busybox brctl delbr $BRIDGE0"
    cmd1="busybox brctl delbr $BRIDGE1"
    tc_info "testing \"$cmd0\""
    tc_info "testing \"$cmd1\""
    $cmd0 >$stdout 2>$stderr &&
    $cmd1 >$stdout 2>$stderr
    tc_fail_if_bad $? "Could not delete bridges" || return

    unset BRIDGE0 BRIDGE1

    tc_pass
}

function do_bunzip2()
{
    cp $BB_DIR/bzip_me.txt.bz2 $BB_DIR/bzip_me.txt-orig $TCTMP/
    local cmd="busybox bunzip2 $TCTMP/bzip_me.txt.bz2"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return

    diff $TCTMP/bzip_me.txt $TCTMP/bzip_me.txt-orig >$stdout 2>$stderr
    tc_pass_or_fail $? "Miscompare of bzip_me.txt and bzip_me.txt-orig"
}

function do_busybox()
{
    busybox >$stdout 2>$stderr
    grep -q "BusyBox .* multi-call binary" $stdout
    tc_pass_or_fail $? "Expected to see \"BusyBox ... multi-call binary\" in stdout"
}

function do_bzcat()
{
    local cmd="busybox bzcat $BB_DIR/bzip_me.txt.bz2"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    diff $BB_DIR/bzip_me.txt-orig $stdout
    tc_pass_or_fail $? "miscompare of stdout"
}

function do_bzip2()
{
    cp $BB_DIR/bzip_me.txt-orig $TCTMP/
    cp $BB_DIR/bzip_me.txt-orig $TCTMP/bzip_me.txt
    local cmd="busybox bzip2 $TCTMP/bzip_me.txt"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return

    local cmd="bunzip2 $TCTMP/bzip_me.txt.bz2"  # intentionally don't insist on BB version
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return

    diff $TCTMP/bzip_me.txt $TCTMP/bzip_me.txt-orig >$stdout 2>$stderr
    tc_pass_or_fail $? "Miscompare of bzip_me.txt and bzip_me.txt-orig"
}

function do_cal()
{
    local cmd="busybox cal"
    export LANG=C
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    grep -q $(date +%B) $stdout
    tc_fail_if_bad $? "Expected to see $(date +%B) in stdout" || return
    cmd="busybox cal -y"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    local m
    for m in January February March April May June July \
        August September October November December
    do
        grep -q $m $stdout
        tc_fail_if_bad $? "Did not see $m in stdout" || return
    done
    tc_pass
}

function do_cat()
{
    local file=$TCTMP/xxx
    test_text="testing busybox cat"
    echo "$test_text" > $file
    [ "`busybox cat $file 2>$stderr`" = "$test_text" ]
    tc_pass_or_fail $? "unexpected output"
}

function do_catv()
{
    echo "abc " | busybox catv -e >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"ctv abc \"" || return
    grep -q "abc $\$" $stdout
    tc_pass_or_fail $? "expected to see \"abc $\" in stdout"
}

function do_chat()
{
    do_insufficient $1 "Requires attached modem."
}

function do_chattr()
{
    tc_root_or_break || return
    tc_is_fstype $TCTMP nfs && do_declined $1 "not supported on nfs mounted root systems." && return
    cp $0 $TCTMP/chattr_test
    local cmd="busybox chattr +i $TCTMP/chattr_test"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    rm -f $TCTMP/chattr_test &>$stdout
    local RC=$?
    ((RC!=0))
    tc_fail_if_bad $? "expected to get bad RC from rm of immutable file. Got $RC" || return
    local cmd="busybox chattr -i $TCTMP/chattr_test"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    rm -f $TCTMP/chattr_test &>$stdout
    tc_fail_if_bad $? "unable to remove mutable file" || return
    ! ls $TCTMP/chattr_test &>$stdout
    tc_fail_if_bad $? "mutable file is still there!" || return

    tc_pass
}

function do_chgrp()
{
    tc_root_or_break || return
    tc_exec_or_break rm touch grep || return
    tc_add_group_or_break || return
    rm $TCTMP/xxx
    touch $TCTMP/xxx   # should have group "root"
    busybox chgrp $TC_TEMP_GROUP $TCTMP/xxx >$stdout 2>$stderr
    ls -l $TCTMP/xxx | grep "$TC_TEMP_GROUP" >/dev/null 2>>$stderr
    tc_pass_or_fail $? "unexpected output"
}

function do_chmod()
{
    tc_exec_or_break rm touch cut || return
    local origmask=`umask`
    selinuxenabled
    if [ $? -eq 0 ]
    then
	local act1 exp1="----------." cmd1="a-rwx"
	local act2 exp2="-rwxrwxrwx." cmd2="a+rwx"
	local act3 exp3="---x--x--x." cmd3="a-rw"
	local act4 exp4="--wx-wx-wx." cmd4="a+w"
	local act5 exp5="-rwxrwx-wx." cmd5="ug+r"
	local act6 exp6="---x--x--x." cmd6="ugo-rw"
	local act7 exp7="-r-xr-x--x." cmd7="ug+r"
	local act8 exp8="-r--r-----." cmd8="ugo-x"
	local act9 exp9="-rw-r-----." cmd9="u+w"
	local acta expa="-rwxr-xr-x." cmda="755"
    else
	local act1 exp1="----------" cmd1="a-rwx"
	local act2 exp2="-rwxrwxrwx" cmd2="a+rwx"
	local act3 exp3="---x--x--x" cmd3="a-rw"
	local act4 exp4="--wx-wx-wx" cmd4="a+w"
	local act5 exp5="-rwxrwx-wx" cmd5="ug+r"
	local act6 exp6="---x--x--x" cmd6="ugo-rw"
	local act7 exp7="-r-xr-x--x" cmd7="ug+r"
	local act8 exp8="-r--r-----" cmd8="ugo-x"
	local act9 exp9="-rw-r-----" cmd9="u+w"
	local acta expa="-rwxr-xr-x" cmda="755"
    fi 
    rm $TCTMP/xxx
    touch $TCTMP/xxx
    local failed=""
    for x in 1 2 3 4 5 6 7 8 9 a; do    # count must match the above!
        eval busybox chmod \$cmd$x $TCTMP/xxx >$stdout 2>$stderr
        eval act$x=`ls -l $TCTMP/xxx | cut -d" " -f1`
        if ! eval [ \$exp$x = \$act$x ] ; then
            eval failed="\" \$cmd$x failed with \$act$x expected \$exp$x\""
            break
        fi
    done
    [ "$failed" = "" ]
    tc_pass_or_fail $? "$failed"
}

function do_chown()
{
    tc_root_or_break || return
    tc_exec_or_break grep || return
    tc_add_user_or_break || return
    touch $TCTMP/chowntest
    busybox chown $TC_TEMP_USER $TCTMP/chowntest >$stdout 2>$stderr
    local result="`ls -l $TCTMP/chowntest`"
    echo $result$ | grep $TC_TEMP_USER >/dev/null
    tc_pass_or_fail $? "result: $result"
}

function do_chpasswd()
{
    tc_add_user_or_break || return
    local user=$TC_TEMP_USER

    local shadow_line1=$(grep $user /etc/shadow)

    echo $user:etu357dgj | busybox chpasswd >$stdout 2>$stderr
    tc_ignore_warnings "chpasswd: password for '$user' changed"
    tc_fail_if_bad $? "unexpected response from \"echo $user:etu357dgj | busybox chpasswd\"" || return


    local shadow_line2=$(grep $user /etc/shadow)

    [ "$shadow_line1" != "$shadow_line2" ]
    tc_pass_or_fail $? "Expected \"$shadow_line1\" to differ from \"$shadow_line1\""
}


function do_chroot_shell_no_ldd()
{

    local REAL_LIB=/lib
    [ "$TC_OS_ARCH" = "x86_64" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "ppc64" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "s390x" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "ppc64le" ] && REAL_LIB=/lib64

    cp $REAL_LIB/libreadline.so.* $TCTMP/fakeroot$REAL_LIB
    cp $REAL_LIB/libhistory.so.* $TCTMP/fakeroot$REAL_LIB
    cp $REAL_LIB/libncurses.so.* $TCTMP/fakeroot$REAL_LIB
    cp $REAL_LIB/libdl.so.* $TCTMP/fakeroot$REAL_LIB
    cp $REAL_LIB/libc.so.* $TCTMP/fakeroot$REAL_LIB
    cp $REAL_LIB/ld*.so.* $TCTMP/fakeroot$REAL_LIB
    cp /lib/ld*.so.* $TCTMP/fakeroot/lib/

    busybox chroot $TCTMP/fakeroot $SHELL /doit >$stdout 2>$stderr
    cat $TCTMP/fakeroot/hello.txt | grep "Hello Sailor" >/dev/null
    if [ $? -ne 0 ] ; then
        tc_info "Since there is no ldd on this system,"
        tc_info "this testcase used a hard-coded list"
        tc_info "of libraries that $SHELL is expectd"
        tc_info "to require. If this list is wrong,"
        tc_info "it may be the cause of this failure."
        tc_info "Please investigate and see if the"
        tc_info "hard-coded list needs to change."
        tc_pass_or_fail 1 "did not execute script in chrooted jail"
    else
        tc_pass_or_fail 0
    fi
}

function do_chpst()
{
    tc_add_user_or_break || {
        do_insufficient $1 "no facilities to add users"
        return 0
    }

    local my_user=$TC_TEMP_USER
    local my_prog=$TCTMP/my_prog.sh
    local env_dir=$TCTMP/env_dir
    mkdir $env_dir

    cat<<EOF >$my_prog
#!/bin/sh
env
EOF
    chmod go-x $my_prog
    chmod u+x $my_prog
    chown $my_user $my_prog

    # file to set env variable KKK to ZZZ
    echo "ZZZ" > $env_dir/KKK
    chmod go-x $env_dir/KKK
    chown $my_user $env_dir
    chown $my_user $env_dir/KKK

    tc_info "testing switch users, set environment"
    cmd="busybox chpst -u $my_user -e $env_dir $my_prog"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response to \"$cmd\"" || return
    grep -q KKK=ZZZ $stdout
    tc_fail_if_bad $? "Expected to see \"ZZZ\" in stdout" || return

    local my_prog_fails=$TCTMP/my_prog_fails.sh
    cat<<EOF >$my_prog_fails
#!/bin/sh
cat $env_dir/KKK | cat | cat > $env_dir/this_should_fail
EOF
    chmod go-x $my_prog_fails
    chmod u+x $my_prog_fails
    chown $my_user $my_prog_fails

    # Note: There is a delicate balance between "-o 6" and the number of cat
    #       commands in the above script. This makes it work both when run
    #       from a scenario file and when run stand-alone from its own dir.
    #       This is a bit shaky and I anticipate trouble! May need a better
    #       way to control the number of open files.
    tc_info "testing limiting number of open files for user/process"
    tot_fds=`ls /proc/$$/fd | wc -w`	
    cmd="busybox chpst -o $tot_fds -u $my_user $my_prog_fails"
    $cmd &>$stdout
    grep -iq "Too many open files" $stdout
    tc_pass_or_fail $? "Expected to see \"Too many open files\" in stdout"

}

function do_chroot_shell_ldd()
{

    local REAL_LIB=/lib
    [ "$TC_OS_ARCH" = "x86_64" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "ppc64" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "s390x" ] && REAL_LIB=/lib64
    [ "$TC_OS_ARCH" = "ppc64le" ] && REAL_LIB=/lib64
	
    ldd $SHELL > $TCTMP/libs
    while read name junk lib junk ; do
        [ "${name:0:1}" = "/" ] && cp $name $TCTMP/fakeroot$name && continue # if fully qualified
        [ -e "$lib" ] && cp $lib $TCTMP/fakeroot$REAL_LIB
    done < $TCTMP/libs

    busybox chroot $TCTMP/fakeroot $SHELL /doit >$stdout 2>$stderr
    tc_fail_if_bad $? "chroot failed" || return
    cat $TCTMP/fakeroot/hello.txt 2>$stderr | grep "Hello Sailor" >$stdout 2>>$stderr
    tc_pass_or_fail $? "did not execute script in chrooted jail"
}

function do_chroot()
{
    tc_root_or_break || return

    mkdir -p $TCTMP/fakeroot/bin
    mkdir -p $TCTMP/fakeroot/lib
    mkdir -p $TCTMP/fakeroot/lib64
    cat > $TCTMP/fakeroot/doit <<-EOF
#!$SHELL
# something to run in fakeroot
echo "Hello Sailor" > hello.txt
EOF
    chmod +x $TCTMP/fakeroot/doit
    cp $(which echo) $TCTMP/fakeroot/bin

    if tc_is_busybox $SHELL ; then
        cp `which busybox` $TCTMP/fakeroot/bin
    else
        cp $SHELL $TCTMP/fakeroot/$SHELL
    fi

    tc_executes ldd && {
        do_chroot_shell_ldd
        return
    }
    do_chroot_shell_no_ldd
}

function do_chvt()
{
    tc_root_or_break || return
    [ -a /dev/tty4 ] ||     do_insufficient $1 "tty4 not available" && return 0
    busybox chvt 4 >$stdout 2>$stderr   # only test is that it doesn't crash and burn
    tc_pass_or_fail $? "unexpected output"
}

function do_clear()
{
    busybox clear >$stdout 2>$stderr    # only test is that it doesn't crash and burn
    echo " (screen cleared)"   # pretty-up the output a little
    tc_pass_or_fail $? "unexpected output"
}

function do_cp()
{
    tc_exec_or_break mkdir ln || return
    mkdir $TCTMP/dir1
    mkdir $TCTMP/dir2
    mkdir $TCTMP/dir3
    mkdir $TCTMP/dir4
    echo "some text" > $TCTMP/dir1/myfile
    echo "some other text" > $TCTMP/dir2/myotherfile
    ln -s $TCTMP/dir1/myfile $TCTMP/dir2/mysymlink
    ln    $TCTMP/dir1/myfile $TCTMP/dir3/myhardlink
    busybox cp $TCTMP/dir1/* $TCTMP/dir4
    busybox cp -d $TCTMP/dir2/* $TCTMP/dir4 # no deref symlinks
    busybox cp $TCTMP/dir3/* $TCTMP/dir4
    tc_pass_or_fail $? "unexpected output"
}

function do_cut()
{
    local result1=`echo "a|b|OK|c" | busybox cut -f3 -d"|" 2>$stderr`
    local result2=`echo "a OK b c" | busybox cut -f2  -d" " 2>>$stderr`
    [ "$result1" = "OK" ] && [ "$result2" = "OK" ]
    tc_pass_or_fail $? "unexpected output"
}

function do_date()
{
    tc_exec_or_break sleep || return
    local start finis delta
    declare -i start finis delta
    tc_info "Pausing for 5 seconds..."
    start=`busybox date +%s`
    sleep 5
    finis=`busybox date +%s`
    let delta=$finis-$start
    [ $delta -ge 4 ] && [ $delta -le 6 ]
    tc_pass_or_fail $? "unexpected output"
}

function do_dd()
{
    tc_exec_or_break grep || return
    local actual1 actual2 failed expected1 expected2
    expected1="8+0 records out"
    expected2="8388608"
    actual1=`busybox dd if=/dev/zero of=$TCTMP/image bs=1024k count=8 2>&1 \
        | grep "$expected1" 2>$stderr`
    actual2=`ls -l $TCTMP/image | grep "$expected2"`
    failed="expected \"$expected1\", got \"$actual1\"
            expected \"$expected2\", got \"$actual2\""
    [ "$actual1" ] && [ "$actual2" ]
    tc_pass_or_fail $? "$failed"
}

function do_df()
{
    # We need to handle "busybox df /" for 5.2 release after fix for Bug #39586. 
    # Also in future we may want to handle "busybox df" over NFS. Deferred Bug #38821.  
    # We have a 5.2 testcase Bug #39616, for tracking above issues.
    #
    # UPDATE: This test has been changed to re-enable "df /" as that appears to be fixed
    # (bug 39586). At this point, nothing done about NSF.
    tc_exec_or_break grep || return
    busybox df / >$stdout 2>$stderr
    if [ $TC_OS_ARCH = ppcnf ]; then
    	NFS_ROOT=`sed 's/ /\n/g' /proc/cmdline | grep "nfsroot" | cut -d"=" -f2`
    	grep $NFS_ROOT $stdout >/dev/null 2>$stderr
    else
    	grep "\/dev" $stdout >/dev/null 2>$stderr || grep "rootfs" $stdout >/dev/null 2>$stderr
    fi
    tc_pass_or_fail $? "unexpected output"
}

function do_dirname()
{
    tc_exec_or_break touch mkdir || return
    mkdir -p $TCTMP/dir
    touch $TCTMP/dir/file
    local dirname=`busybox dirname $TCTMP/dir/file 2>$stderr`
    [ "$TCTMP/dir" = "$dirname" ]
    tc_pass_or_fail $? "unexpected output"
}

function do_dmesg()
{
    busybox dmesg 2>$stderr >$stdout
    tc_pass_or_fail $? "unexpected results"
}

function do_du()
{
    local result1 result2 size1 size2
    declare -i size1 size2
    result1=`busybox du -s $TCTMP 2>>$stderr`
    echo "Hello Sailor" > $TCTMP/du_test
    result2=`busybox du -s $TCTMP 2>>$stderr`
    read size1 junk <<-EOF
`echo $result1`
EOF
    read size2 junk <<-EOF
`echo $result2`
EOF
    [ $size2 -gt $size1 ]
    tc_pass_or_fail $? "expected \"$size1\" to be greater than \"$size1\""
}

function do_echo()
{
    tc_exec_or_break grep || return
    busybox echo "hello sailor" 2>$stderr | \
        grep "hello sailor" > /dev/null
    tc_pass_or_fail $? "unexpected output"
}

function do_egrep()
{
    tc_exec_or_break mkdir || return
    mkdir $TCTMP/egreptest
    local pwd=$PWD
    cd $TCTMP/egreptest
    cat > egrepfile1 <<-EOF
things
kings
wings
EOF
    cat > egrepfile2 <<-EOF
things
kings
wings
sealing
EOF
    local result="`busybox egrep -c \"hing|king\" * 2>$stderr`"
    local expected=$'egrepfile1:2\negrepfile2:2'
    [ "$result" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$result\""
    cd $pwd
}

function do_env()
{
    tc_exec_or_break grep || return
    export do_env="hello sailor"
    local answer=`busybox env | grep do_env | grep "hello sailor"`
    tc_pass_or_fail $? "environment value not found"
}

function do_eject()
{
    tc_exists /dev/cdrom || {
         do_insufficient $1 "Missing cdrom drive."
         return 0
    }
    local cmd="busybox eject -s"
    $cmd >$stdout 2>$stderr
    tc_pass_or_fail $? "unexpected response from \"$cmd\"" || return
}

function do_expand()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep cat || return

        echo "1         a       " >$TCTMP/expand.txt
        echo "3         b       " >>$TCTMP/expand.txt
        echo "4         c       " >>$TCTMP/expand.txt
        echo "54321     d       " >>$TCTMP/expand.txt

        busybox expand $TCTMP/expand.txt > /dev/null 2>>$stderr
        tc_pass_or_fail $?  "$summary2" || return
}

function do_expr()
{
        tc_exec_or_break || return

        local val1=`busybox expr 7 \* 6 2>>$stderr`
        local exp1=42
        local val2=`busybox expr length "hello sailor" 2>>$stderr`
        local exp2=12
        local val3=`busybox expr "abc" : "a\(.\)c" 2>$stderr`
        local exp3=b
        local failure
        [ "$val1" != "$exp1" ] && \
                failure="expected $exp1, got $val1"
        [ -z "$failure" ] && [ "$val2" != "$exp2" ] && \
                failure="expected $exp2, got $val2"
        [ -z "$failure" ] && [ "$val3" != "$exp3" ] && \
                failure="expected $exp3, got $val3"
        [ -z "$failure" ]
        tc_pass_or_fail $? "$failure"
}

function do_false()
{
    ! busybox false >$stdout 2>$stderr
    tc_pass_or_fail $? "unexpected output"
}

function do_fdflush()
{
    tc_exec_or_break mount || return
    tc_exists /dev/fd0 || {
         do_insufficient $1 "Missing floppy drive."
         return 0
    }
    tc_info "This may take a while to time out if there"
    tc_info "is no floppy in the drive or if there is no"
    tc_info "floppy drive at all."
    mkdir $TCTMP/floppy_mount
    if ! cat /etc/mtab | grep "\/dev\/fd0" >/dev/null ; then
        mount /dev/fd0 $TCTMP/floppy_mount &>/dev/null || {
             do_insufficient $1 "No floppy in drive."
             return 0
        }
        $UMOUNT $TCTMP/floppy_mount &>/dev/null
    fi
    busybox fdflush /dev/fd0 2>$stderr >$stdout
    tc_pass_or_fail $? "bad response from \"busybox fdflush\""
}

function do_fdformat()
{
    do_declined $1 "Requires manual intervention to insert floppy."
}

function do_fdisk()
{
    tc_get_os_arch
    [ "$TC_OS_ARCH" = "s390x" ] && do_insufficient $1 "not supported on s390x" && return

    busybox fdisk -l 1>$stdout 2>$stderr
    tc_pass_or_fail $? "busybox fdisk command failed."
}

function do_fgrep()
{
    tc_exec_or_break mkdir || return
    mkdir $TCTMP/fgreptest
    local pwd=$PWD
    cd $TCTMP/fgreptest
    cat > fgrepfile1 <<-EOF
things
kings
wings
EOF
    cat > fgrepfile2 <<-EOF
things
kings
wings
sealing
EOF
    local result="`busybox fgrep -c \"[hkl]ing\" * 2>$stderr`"
    local expected=$'fgrepfile1:0\nfgrepfile2:0'    # Note, this is a negative test becuase that is what essentially needs to be tested.
    [ "$result" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$result\""
    cd $pwd
}


function do_find()
{
    tc_exec_or_break touch chmod rm || return
    touch $TCTMP/touched
    local found1=`busybox find $TCTMP -name "touched" -print 2>$stderr`
    rm $TCTMP/touched
    local found2=`busybox find $TCTMP -name "touched" -print 2>$stderr`
    [ "$found1" ] && [ -z "$found2" ]
    tc_pass_or_fail $? \
    "expected \"$found1\" to be non-blank and \"$found2\" to be blank"
}

function do_fold()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep || return

        echo "one is that.              one is this." > $TCTMP/fold.txt
        echo "two is this.              two is that." >> $TCTMP/fold.txt

        busybox fold -w 20 $TCTMP/fold.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox fold -w 20 $TCTMP/fold.txt | grep -c one | grep 2 >& /dev/null
        tc_pass_or_fail $?  "$summary3"
}

function do_free()
{
    local result=`busybox free 2>$stderr`
    [ "$result" ]
    tc_pass_or_fail $? "got no output from \"busybox free\""
}

function do_fsck()
{
    tc_exec_or_break dd mkfs.ext2 || return
   
	dd bs=1024  if=/dev/zero of=$TCTMP/tmp_fs count=2048 &>$stdout # output goes to stderr
	tc_break_if_bad $? "Error while trying to create temp fs" || return

	mkfs.ext2 -F $TCTMP/tmp_fs  &>$stdout 
	tc_break_if_bad $? "mkfs ext2 failed on tmp fs" || return

    busybox fsck -y -t ext2 $TCTMP/tmp_fs &>$stdout # some of the output goes to stderr
    # We need to use -y so that it does not throw an error saying it needs an interactive terminal.
    tc_pass_or_fail $? "fsck failed on $TCTMP/tmp_fs"
    
}

function do_fsck.minix()
{
    tc_exec_or_break dd mkfs.minix || return
   
	dd bs=1024  if=/dev/zero of=$TCTMP/tmp_fs count=2048 &>$stdout # output goes to stderr
	tc_break_if_bad $? "Error while trying to create temp minix fs" || return

	mkfs.minix $TCTMP/tmp_fs  &>$stdout 
	tc_break_if_bad $? "mkfs ext2 failed on tmp fs" || return

    busybox fsck.minix $TCTMP/tmp_fs &>$stdout # some of the output goes to stderr
    tc_pass_or_fail $? "fsck failed on $TCTMP/tmp_fs"
    
}

function do_fuser()
{
    TC_PID=`echo $$`
    busybox fuser $0 | grep  $TC_PID >$stdout 2>$stderr
    tc_pass_or_fail $? "fuser could not find current process PID in its output."
}

function do_grep()
{
    tc_exec_or_break mkdir || return
    mkdir $TCTMP/greptest
    local pwd=$PWD
    cd $TCTMP/greptest
    cat > grepfile1 <<-EOF
things
kings
wings
EOF
    cat > grepfile2 <<-EOF
things
kings
wings
sealing
EOF
    local result="`busybox grep -c \"[hkl]ing\" * 2>$stderr`"
    local expected=$'grepfile1:2\ngrepfile2:3'
    [ "$result" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$result\""
    cd $pwd
}

function do_gunzip()
{
    tc_exec_or_break touch || return   
    local pwd=$PWD
    cd $TCTMP
    cat > a <<-EOF
some
junk
data
EOF
    cat > b <<-EOF
some more data in file b
EOF
    touch c
    busybox gzip a b c 1>$stdout 2>$stderr
    tc_break_if_bad $? "gzip failed" || return
    ls a.gz b.gz c.gz 1>$stdout 2>$stderr
    tc_break_if_bad $? "gzip failed" || return
    busybox gunzip a.gz b.gz c.gz 1>$stdout 2>$stderr
    tc_fail_if_bad $? "gunzip failed" || return
    ls a b c 1>$stdout 2>$stderr
    tc_pass_or_fail $? "gunzip failed" || return
    cd $pwd
}

function do_gzip()
{
    tc_exec_or_break touch || return   
    local pwd=$PWD
    cd $TCTMP
    cat > a <<-EOF
some
junk
data
EOF
    cat > b <<-EOF
some more data in file b
EOF
    touch c
    busybox gzip a b c 1>$stdout 2>$stderr
    tc_break_if_bad $? "gzip failed" || return
    ls a.gz b.gz c.gz 1>$stdout 2>$stderr
    tc_pass_or_fail $? "gzip failed" || return
    cd $pwd
}

function do_halt()
{
    do_declined $1 "This command will crash the system."
}

function do_head()
{
    local expected=$'line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nlinea'
    local head="`(for n in 1 2 3 4 5 6 7 8 9 a b c d e f ; do
        echo line$n
    done) | busybox head`"
    [ "$head" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$head\""
}

function do_hexdump()
{
        echo "1 2 3" > $TCTMP/hexdump.txt
        echo "4 5 6" >> $TCTMP/hexdump.txt

        busybox hexdump $TCTMP/hexdump.txt >$stdout 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        [ -s $stdout ]
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "hexdump -c"

        busybox hexdump -c $TCTMP/hexdump.txt >$stdout 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox hexdump -c $TCTMP/hexdump.txt | grep \\n >& $stdout
        tc_fail_if_bad $?  "-c $summary3" || return

        tc_info "hexdump -s"

        busybox hexdump -s 2 $TCTMP/hexdump.txt >$stdout 2>$stderr
        tc_fail_if_bad $?  "-s $summary2" || return

        [ -s $stdout ]
        tc_pass_or_fail $?  "-s $summary2"
}

function do_hostid()
{
        busybox hostid >$stdout 2>$stderr
        tc_fail_if_bad $?  "Unexpected response from hostid command" || return

        busybox hostid > $TCTMP/hostid_value.txt

        egrep -q '[[:xdigit:]]*$' $TCTMP/hostid_value.txt
        tc_pass_or_fail $?  "Busybox hostid command failed"

}

function do_hostname()
{
    tc_exist_or_break /proc/sys/kernel/hostname || return
    local HOSTNAME="`cat /proc/sys/kernel/hostname`."
    local expected=${HOSTNAME%%.*}
    local actual="`busybox hostname -s`"
    [ "$actual" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$actual\""
}

function do_hwclock()
{
    [ $TC_OS_ARCH = s390x ] || [ $TC_OS_ARCH = ppcnf ] && {
        tc_info "hwclock not supported"
        return 0
    }
    busybox hwclock >$stdout  2>$stderr
    tc_fail_if_bad $? "unexpected response from \"busybox hwclock\"" || return

    grep -q seconds $stdout
    tc_fail_if_bad $? "expected to see \"seconds\" in stdout" || return

    # set hardware clock to system clock
    busybox hwclock -w >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"busybox hwclock -w\"" \
                        "WARNING: HARDWARWE CLOCK MAY BE MESSED UP!" || return

    # set system clock to hardware clock
    busybox hwclock -s >$stdout 2>$stderr
    tc_pass_or_fail $? "unexpected response from \"busybox hwclock -s\"" \
                        "WARNING: SYSTEM CLOCK MAY BE MESSED UP!" || return

}

function do_id()
{
    tc_exec_or_break grep || return
    local actual=`busybox id \`whoami\` 2>$stderr`
    local actual1=`echo $actual | grep "(\`whoami\`)"`
    local actual2=`echo $actual | grep uid=`
    local actual3=`echo $actual | grep gid=`
    local actual4=`echo $actual | grep groups=`
    [ "$actual1" ] && \
    [ "$actual2" ] && \
    [ "$actual3" ]
    tc_pass_or_fail $? "expected \"(`whoami`)\", \"uid=\", \"gid=\", got \"$actual\""
}

function do_ifconfig()
{
    tc_exec_or_break grep || return
    busybox ifconfig 2>$stderr >$stdout
    tc_fail_if_bad $? "bad result from \"busybox ifconfig\"" || return

    cat $stdout | grep "^lo.*Link.*Loopback" >/dev/null
    tc_fail_if_bad $? "bad output from busybox ifconfig" \
        "Expected to see \"lo ... Link ... Loopback\" in stdout" || return

    [ "$IPV6" = "yes" ] && {
        cat $stdout | grep "inet6" >/dev/null
        tc_fail_if_bad $? "Did not see IPV6 info" || return
    }
    tc_pass_or_fail 0   # pass if we get this far
}

function do_ip()
{
    do_ipaddr || return
    do_iptunnel || return
    tc_pass
}

function do_ipaddr()
{
    tc_info "ip addr"
    tc_exec_or_break grep || return
    busybox ip addr 2>$stderr >$stdout
    tc_fail_if_bad $? "bad result from \"busybox ipaddr\"" || return

    cat $stdout | grep "LOOPBACK,UP" >/dev/null
    tc_fail_if_bad $? "bad output from busybox ip addr" \
        "Expected to see \"LOOPBACK,UP\" in stdout" || return

    [ "$IPV6" = "yes" ] && {
        cat $stdout | grep "inet6" >/dev/null
        tc_fail_if_bad $? "Did not see IPV6 info" || return
    }
    return 0
}

function do_ipcrm()
{
        # Check if supporting utilities are available
        tc_exec_or_break busybox ipcs || return

        local id=12123210
        id=`$MyDIR/sem_ipcrm`

        if [ -z "$id" -o $id -eq 12123210 ]; then
                tc_break_if_bad 1 "Unable to create a semaphore to test further."
                return
        fi

        busybox ipcrm -s $id > $stdout 2>>$stderr
        tc_fail_if_bad $?  "sem $summary2" || return

        busybox ipcs | grep -v $id >& $stdout
        tc_pass_or_fail $?  "sem $summary3"
}


function do_ipcs()
{
        busybox ipcs >$stdout 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox ipcs | grep Semaphore >& $stdout
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "ipcs -q"
      
        busybox ipcs -q >$stdout 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox ipcs -q | grep -v Semaphore >& $stdout
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "ipcs -m"
      
        busybox ipcs -m >$stdout 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox ipcs -m | grep -v Semaphore >& $stdout
        tc_pass_or_fail $?  "$summary3"
}

function do_iptunnel()
{
    modprobe sit
    busybox ip tunnel 2>$stderr >$stdout
    local rc=$?
    [ "$IPV6" = "yes" ] && {
        cat $stdout | grep "ipv6" >/dev/null
        tc_fail_if_bad $? "Did not see IPV6 info from ip tunnel" || return
    }
    tc_pass_or_fail $rc "bad result from \"busybox ip tunnel\"" || return
}


function do_insmod()
{
    local my_mod=dummy
    local my_mod_dir=/lib/modules/$(uname -r)/kernel/drivers/net
    tc_exists $my_mod_dir/$my_mod.ko || {
        my_mod=fiv_module
        my_mod_dir=/opt/fiv/fiv_module
    }
    tc_exists $my_mod_dir/$my_mod.ko || {
        # module not available
        do_insufficient $1 "no fiv_module.ko nor dummy.ko found."
        return 0
    }

    tc_info "using $my_mod_dir/$my_mod.ko"

    tc_exec_or_break dmesg rmmod grep diff || return

    rmmod $my_mod >$stdout 2>$stderr   # just in case

    cat /proc/modules > $TCTMP/before
    busybox insmod $my_mod_dir/$my_mod.ko 2>$stderr >$stdout
    tc_fail_if_bad $? "unexpected results from busybox insmod $my_mod_dir/$my_mod" || return

    cat /proc/modules > $TCTMP/after
    diff $TCTMP/before $TCTMP/after | grep -q $my_mod
    tc_fail_if_bad $? "module $my_mod not in installed modules list" || return

    rmmod $my_mod >$stdout 2>$stderr
    tc_break_if_bad $? "cannot rmmod $my_mod after installing it"

    tc_pass_or_fail 0 # pass if we get this far
}

function do_kill()
{
    local bb_kill=$(which bb_kill)
    tc_exec_or_break $bb_kill rm ps grep || return

    local pgmname="bb_kill$$"
    local grepfor="[b]b_kill$$"
    cp $bb_kill $TCTMP/$pgmname

    local ps_cmd="ps --format pid,command"
    tc_is_busybox ps && ps_cmd=ps

    eval "$TCTMP/$pgmname" &
    local i=0
    while [ $i -lt 10 ] ; do
        local process=$($ps_cmd | grep "$grepfor")
        [ "$process" ] && break
        tc_info "Waiting for $pgmname to start"
        let i+=1
        sleep 1
    done
    [ "$process" ]
    tc_break_if_bad $? "unable to start $pgmname" || return
    set $process
    local pid=$1

    busybox kill $pid >$stdout 2>$stderr
    tc_fail_if_bad $? "Command busybox kill $pid failed" || return
    i=0
    while [ $i -lt 10 ] ; do
        local process2=$($ps_cmd | grep "$grepfor")
        [ -z "$process2" ] && break
        tc_info "Waiting for $pgmname to die"
        let i+=1
        sleep 1
    done
    [ -z "$process2" ]
    tc_pass_or_fail $? "Unable to kill pid $pid, $pgmname" || ps
}

function do_killall()
{
    local bb_kill=$(which bb_kill)
    tc_exec_or_break $bb_kill rm ps grep || return

    local pgmname="bb_kall$$" # at one time this failed with >15 char names
    local grepfor="[b]b_kall$$"
    cp $bb_kill $TCTMP/$pgmname

    eval "$TCTMP/$pgmname" &
    local i=0
    while [ $i -lt 10 ] ; do
        sleep 1             # Perhaps fix intermittent failure.
        local process=$(ps | grep "$grepfor")
        [ "$process" ] && break
        tc_info "Waiting for $pgmname to start"
        let i+=1
    done
    [ "$process" ]
    tc_break_if_bad $? "unable to start $pgmname" || return
    tc_info "found process $process"    # Added to help debug intermittent failure.

    busybox killall $pgmname >$stdout 2>$stderr
    tc_fail_if_bad $? "Command busybox killall $pgmname failed" || return
    i=0
    while [ $i -lt 10 ] ; do
        local process2=$(ps | grep "$grepfor")
        [ -z "$process2" ] && break
        tc_info "Waiting for $pgmname to die"
        let i+=1
        sleep 1
    done
    [ -z "$process2" ]
    tc_pass_or_fail $? "Unable to killall $pgmname." || ps
}

function do_logname()
{
        tc_exec_or_break wc echo || return
        local actual=`busybox logname 2>&1`
        local words
        declare -i words=`echo $actual | wc -w`
        [ $words -ge 1 ] || [ "$actual" = "logname: no login name" ]
        tc_pass_or_fail $? "expected a username or \"no login name\", got \"$actual\""
}


function do_losetup()
{
	tc_exec_or_break grep || return

	dev=`busybox losetup -f 2>$stderr`
	if [ "$dev" == "" ]; then
		tc_fail "Unable to find free loop device / loop device support unavailable" || return
	fi
	tc_info "losetup : Found free loop device $dev"

	# setup the loop device
	# Copy it to TCTMP to avoid stripping of the long pathlength 
	cp $BB_DIR/compress_test_file.Z $TCTMP/data_file
	tc_wait_for_file $TCTMP/data_file 3
	busybox losetup -o 512 $dev $TCTMP/data_file >$stdout 2>$stderr
	tc_fail_if_bad $? "Unable to setup loop device" || return

	busybox losetup -a >$stdout 2>$stderr
	tc_fail_if_bad $? "Unable to get the list of loop devices" || return

	grep "$dev" $stdout | grep "512" | grep -q "$TCTMP/data_file"
	tc_fail_if_bad $? "$dev was not listed in the losetup"  || return

	busybox losetup -d $dev 2>$stderr
	tc_fail_if_bad $? "Unexpected failure while removing $dev" || return

	busybox losetup -a >$stdout 
	grep -q "$dev" $stdout
	if [ $? -eq 0 ];
	then
		tc_fail "Unable to remove $dev using busybox losetup" || return
	fi
	tc_pass
}

function do_ln()
{
    tc_exec_or_break touch grep || return

    local result expected
    local file=$TCTMP/ln_test_file1
    local symlink=$TCTMP/ln_test_sym
    local hrdlink=$TCTMP/ln_test_hrd
    touch $file

    TCNAME="ln01 - symbolic link"
    busybox ln -s $file $symlink >$stdout 2>$stderr
    result="`ls -l $symlink 2>$stderr`"
    echo $result | grep "^l.*ln_test_sym.*ln_test_file1" >/dev/null
    tc_fail_if_bad $? \
        "expected to see symlink from $file to $symlink in \"$result\"" || return

    TCNAME="ln02 - hard link"

    busybox ln $file $hrdlink >$stdout 2>$stderr
    result="`ls -l $hrdlink 2>$stderr`"
    echo $result | grep "^-.* 2 .*ln_test_hrd$" >/dev/null
    tc_pass_or_fail $? \
        "expected to see link count of 2 for ln_test_hrd in \"$result\""
}

function do_ls()
{
        tc_exec_or_break touch || return

        touch $TCTMP/ls_test_
        local result="`busybox ls $TCTMP/ls_test_ 2>$stderr`"
        [ "$result" ]
        tc_pass_or_fail $? "ls did not return file named $TCTMP/ls_test_"
}

function do_lsmod()
{
    tc_exec_or_break sed diff || return
    tc_exist_or_break "/proc/modules" || return

    if tc_is_busybox diff ; then
        DIFF_OPTS="-b"
    else
        DIFF_OPTS="-bB"
    fi

    cut -d" " -f1 /proc/modules > $TCTMP/modules1
    busybox lsmod 2>$stderr | grep -v "^Module" | cut -d" " -f1 > $TCTMP/modules2
    cut -d" " -f1 /proc/modules > $TCTMP/modules3
    diff $DIFF_OPTS $TCTMP/modules1 $TCTMP/modules2 > $TCTMP/diffout1 ||
    diff $DIFF_OPTS $TCTMP/modules3 $TCTMP/modules2 > $TCTMP/diffout2
    tc_pass_or_fail $? "unexpected result" || {
        RC=$?
        tc_info "======= expectd ========"$
        cat $TCTMP/modules1
        tc_info "======= actual ========="$
        cat $TCTMP/modules2
        tc_info "======= difference ====="$
        cat $TCTMP/diffout1
        tc_info "======= current ========"$
        cat $TCTMP/modules3
        tc_info "=== 2nd difference ====="$
        cat $TCTMP/diffout2
        tc_info "========================"$
        return $RC
    }
}

function do_md5sum()
{
    # Check if supporting utilities are available
    tc_exec_or_break  echo grep || return

    echo "1" > $TCTMP/md5sum.txt
    echo "2" >> $TCTMP/md5sum.txt
    echo "a" >> $TCTMP/md5sum.txt
    echo "b" >> $TCTMP/md5sum.txt

    busybox md5sum  $TCTMP/md5sum.txt >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \" md5sum  $TCTMP/md5sum.txt\"" || return

    local expected=d4a59fc154c4bba3dd6aa3f5a81de972
    grep -q $expected $stdout 2>$stderr
    tc_fail_if_bad $?  "Expected to see \"$expected\" in stdout" || return

    tc_info "md5sum -c"

    busybox md5sum  $TCTMP/md5sum.txt >$TCTMP/md5sum.tst 2>$stderr

    busybox md5sum -c  $TCTMP/md5sum.tst >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \"md5sum -c\"" || return

    grep OK $stdout 2>$stderr
    tc_pass_or_fail $? "Expected to see \"OK\" in stdout"
}

function do_mesg()
{
        tc_info "NOTE1: We cannot redirect output from mesg command since" \
        "it checks for tty. So we can't confirm output, just return code."

        tc_info "NOTE2: This will FAIL when run under LTP harness." \
                "(\"Inappropriate ioctl\")" \
                "Please run it manually."
        return

        # cannot redirect stderr for mesg ?!
        busybox mesg y >/dev/null
        busybox mesg >/dev/null
        tc_fail_if_bad $? "unexpected response1" || return

        busybox mesg n >/dev/null
        busybox mesg >/dev/null
        tc_pass_or_fail $? "unexpected response2"
}

function do_mkdir()
{
    tc_exec_or_break grep touch || return
    busybox mkdir $TCTMP/do_mkdir >$stdout 2>$stderr
    touch $TCTMP/do_mkdir/touched
    ls -l $TCTMP/do_mkdir | grep touched >/dev/null
    tc_pass_or_fail $? "`ls -l $TCTMP/do_mkdir`"
}

function do_more()
{
        echo "1: This is a testfile to test the" > $TCTMP/test_file04
        echo "2: more command." >> $TCTMP/test_file04
        echo "3: That's all folks!" >> $TCTMP/test_file04
        echo "4: xyadkan" >> $TCTMP/test_file04

        busybox more $TCTMP/test_file04 >$stdout 2>$stderr
        tc_fail_if_bad $?  "Unexpected response from more command" || return

        busybox grep -q xyadkan $stdout 2>$stderr
        tc_pass_or_fail $?  "expected to see xyadkan in stdout" || return
}

function do_mount()
{
    tc_root_or_break || return
    tc_exec_or_break mkdir gunzip || return

    mkdir $TCTMP/bb_mnt
    cp $LTPBIN/bb_mount.img.gz $TCTMP/bb_mount.img.gz
    gunzip $TCTMP/bb_mount.img.gz

    busybox mount $TCTMP/bb_mount.img $TCTMP/bb_mnt -o loop >$stdout 2>$stderr
    local result="`cat $TCTMP/bb_mnt/status`"
    local expected="filesystem successfully mounted"
    [ "$result" = "$expected" ]
    tc_pass_or_fail $? "$TCTMP/bb_mount.img not mounted on $TCTMP/bb_mnt" || return
    do_umount_ok="yes"      # tested by do_umount function
}

function do_mv()
{
        tc_exec_or_break cat echo || return

        local contents="Hello Sailor"
        echo "$contents" > $TCTMP/original
        busybox mv $TCTMP/original $TCTMP/newname 2>$stderr
        [ "$contents" = "$(<$TCTMP/newname)" ]
        tc_pass_or_fail $? "expected $TCTMP/newname to contain \"$contents\""
}

function do_nc()
{
    local tty_line=$(ls -l /proc/$$/fd/0)
    local tty=${tty_line##* }
    [ "$tty" = "/dev/null" ] && {
        tc_info "$TCNAME: no available tty so skip this test"
        return 0
    }

    tc_find_port
    tc_break_if_bad $? "Could not find available port" || return

    # start server in background
    busybox nc -l -p $TC_PORT -w 30 >$stdout 2>$stderr &
    tc_wait_for_pid  $! 
    tc_fail_if_bad $? "could not start nc server side" || return

    tc_wait_for_active_port $TC_PORT
    tc_fail_if_bad $? "$nc server not listening on $TC_PORT" || return

    sleep 2

    # start ipv4 client
    local my_ipv4_addr=$(hostname -i | cut -d" " -f1 )
    [ "$my_ipv4_addr" ]
    tc_break_if_bad $1 "no ipv4 host" || return

    tc_info "testing ipv4 client as \"echo hello | busybox nc $my_ipv4_addr $TC_PORT\""
    echo "hello ipv4" | busybox nc $my_ipv4_addr $TC_PORT
    tc_fail_if_bad $? "could not start nc client side" || return
    tc_wait_for_file_text $stdout "hello ipv4"
    tc_fail_if_bad $? "Server did not recieve data from client" || return

    # start ipv6 client
# Untested since not yet suppoted by busybox 
#    local my_v6_addr=$TC_IPV6_global_ADDRS
#    [ "$my_v6_addr" ] || my_v6_addr=$TC_IPV6_link_ADDR
#    [ "$my_v6_addr" ] || my_v6_addr=$TC_IPV6_host_ADDR
#    [ "$my_v6_addr" ] || {
#       do_insufficient $1 "no ipv6 addr"
#       return
#    }
#    tc_info "testing ipv6 client as \"echo hello | busybox nc $my_ipv6_addr $TC_PORT\""
#    echo "hello ipv6" | busybox nc $my_v6_addr $TC_PORT
#    tc_fail_if_bad $? "could not start nc client side" || return
#    tc_wait_for_file_text $stdout "hello ipv6"
#    tc_fail_if_bad $? "Server did not recieve data from client" || return

    tc_wait_for_inactive_port $TC_PORT
    tc_pass_or_fail $? "Server did not give up port when done"
}

function do_netstat()
{
    local tester=$(2>&1 busybox netstat -nl)
    [ "${tester/not compiled/}" != "$tester" ] && {
        do_insufficient $1
        return 0
    }
    tc_exec_or_break grep || return
    tc_find_port
    tc_break_if_bad $? "Could not find available port" || return
    
    # start server in background
    busybox nc -l -p $TC_PORT -w 60 >$stdout 2>$stderr &
    tc_wait_for_pid  $!
    tc_fail_if_bad $? "could not start nc server side" || return
    tc_wait_for_active_port $TC_PORT
    tc_fail_if_bad $? "$nc server not listening on $TC_PORT" || return

    busybox netstat -nl 2>$stderr >$stdout
    tc_fail_if_bad $? "bad result from \"busybox netstat -nl \"" || return

    cat $stdout | grep ":$TC_PORT" >/dev/null
    tc_fail_if_bad $? "bad output from busybox netstat -nl" || return 

    tc_pass_or_fail 0   # pass if we get this far
}

function do_nice()
{
        tc_exec_or_break cat echo chmod ps grep || return

cat > $TCTMP/niceme$$ <<-EOF
                #!$SHELL
                # infinite loop script to be niced
                echo \$\$ >$TCTMP/killme
                while : ; do
                        sleep 1
                done
EOF
        chmod +x $TCTMP/niceme$$
        busybox nice -n +10 $TCTMP/niceme$$ >$stdout 2>$stderr &
        tc_fail_if_bad $? "unexpected response from busybox nice -n +10 $TCTMP/niceme$$" || return

        tc_wait_for_file $TCTMP/killme 10 size
        tc_fail_if_bad $? "busybox nice did not start command $TCTMP/niceme$$" || return

        killme=$(<$TCTMP/killme)
        stat=$(</proc/$killme/stat)
        [ "$stat" ]
        tc_break_if_bad $? "could not look at pid $killme status" || return

        set $stat
        shift 18
        nice=$1
        [ $nice = "10" ]
        tc_pass_or_fail $? "expected nice=10 but got nice=$nice for pid $killme" \
                        "=============== /proc/$killme/stat is =========================" \
                        "$stat" \
                        "=============== nice value is in field 19 (1 based) ===========" || return

        kill $killme || kill -9 $killme # kill the niced process
        unset killme
}

function do_nohup()
{
        tc_root_or_break || return
        tc_exec_or_break cat chmod kill ps su grep || return
        tc_add_user_or_break &>/dev/null || return

cat > $TCTMP/hupme$$ <<-EOF
                #!$SHELL
                # infinite loop script to be niced
                echo \$\$       # my pid
                while : ; do
                        sleep 1
                done
EOF
        chmod +x $TCTMP/hupme$$
        chmod a+rwx $TCTMP

        echo "busybox nohup $TCTMP/hupme$$ &>$TCTMP/hupout &" | su -l $TC_TEMP_USER 2>/dev/null
        tc_wait_for_file $TCTMP/hupout 10 size
        tc_fail_if_bad $? "no pid from $TCTMP/hupme$$" || return

        # send hup signal
        local killme=$(<$TCTMP/hupout)
        kill -1 $killme &>/dev/null
        tc_info "We are hoping that pid $killme does NOT go away"
        ! tc_wait_for_no_pid $killme 5
        tc_pass_or_fail $? "Process died but shouldn't have"  || return
        kill $killme || kill -9 $killme # kill the nohupped process
        unset killme
}

function do_nslookup()
{
    tc_exec_or_break grep || return
    busybox nslookup localhost 2>$stderr >$stdout
    tc_fail_if_bad $? "bad result from \"busybox nslookup \"" || return

    cat $stdout | grep "Address.*127.0.0.1.*localhost" >/dev/null
    tc_fail_if_bad $? "bad output from busybox nslookup localhost" \
        "Expected to see \"Address 127.0.0.1 localhost\" in stdout" || return

    [ "$IPV6" = "yes" ] && {
        cp /etc/hosts $TCTMP #To restore in cleanup
        local server_host
        [ "$TC_IPV6_host_ADDRS" ] && server_host=$TC_IPV6_host_ADDRS
        [ "$TC_IPV6_global_ADDRS" ] && server_host=$TC_IPV6_global_ADDRS
        [ "$TC_IPV6_link_ADDRS" ] && server_host=$TC_IPV6_link_ADDRS
        server_host=$(tc_ipv6_normalize $server_host)
        local normalized=$server_host
        local new_name="ipv6-$(hostname)$$"
        echo $normalized $new_name >> /etc/hosts
        type nscd &>/dev/null && nscd -i hosts
        tc_info "looking up $new_name and expecting to see $normalized"
        busybox nslookup $new_name >$stdout 2>$stderr
        tc_fail_if_bad $? "bad response from busybox nslookup $new_name" || return
        grep -q $normalized $stdout
        tc_fail_if_bad $? "Expected to see $normalized in stdout" || return
    }
    tc_pass_or_fail 0       # pass if we get this far
}

function do_od()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep || return

        echo "1" > $TCTMP/od.txt
        echo "2" >> $TCTMP/od.txt
        echo "3" >> $TCTMP/od.txt

        busybox od $TCTMP/od.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox od $TCTMP/od.txt | grep 0000006 >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "od -c"

        busybox od -c $TCTMP/od.txt >/dev/null 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox od -c $TCTMP/od.txt | grep \n >& /dev/null
        tc_pass_or_fail $?  "$summary3"
}

function do_patch()
{
    tc_exec_or_break grep diff || return

	cat > $TCTMP/a.txt <<-EOF
	This file is created to check
	the patch command functionality.
	EOF

        cp $TCTMP/a.txt $TCTMP/a.txt-original
        echo "This line is not there in original file" >> $TCTMP/a.txt

        diff -uN $TCTMP/a.txt-original $TCTMP/a.txt > $TCTMP/patch1
	mv $TCTMP/a.txt-original $TCTMP/a.txt

	cd $TCTMP/
        busybox patch -p0 < patch1 >$stdout 2>$stderr
        tc_pass_or_fail $? "The patch command failed"
}

do_ping()
{
        tc_exec_or_break grep || return

        busybox ping -c1 localhost | grep "1 packets transmitted, 1 packets received, 0% packet loss" >$stdout 2>$stderr
        tc_pass_or_fail $? "ping command failed to send one packet to localhost i.e. itself"
}

do_ping6()
{
    local ipv6_pinged=no
    local cmd=""
    local pingme=""

    local pingme=$TC_IPV6_global_ADDRS
    [ "$pingme" ] && {
        cmd="busybox ping6 -c 1 $pingme"
        tc_info "$cmd (global)"
        $cmd >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from $cmd" || return
        grep -q "bytes from $(tc_ipv6_normalize $pingme)" $stdout
        tc_fail_if_bad $? "didn't get response" || return
        pinged=yes
    }

    local pingme=$TC_IPV6_link_ADDRS
    [ "$pingme" ] && {
        cmd="busybox ping6 -c 1 $pingme"
        tc_info "$cmd (link)"
        $cmd >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from $cmd" || return
        grep -q "bytes from $(tc_ipv6_normalize $pingme)" $stdout
        tc_fail_if_bad $? "didn't get response" || return
        pinged=yes
    }

    local pingme=$TC_IPV6_host_ADDRS
    [ "$pingme" ] && {
        cmd="busybox ping6 -c 1 $pingme"
        tc_info "$cmd (host)"
        $cmd >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from $cmd" || return
        grep -q "bytes from $(tc_ipv6_normalize $pingme)" $stdout
        tc_fail_if_bad $? "didn't get response" || return
        pinged=yes
    }

    [ "$pinged" = "yes" ] || {
        do_insufficient $1 "IPv6 address for this system not available"
        return 0
    }
    tc_pass
}

function do_pwd()
{
    tc_exec_or_break mkdir grep || return
    mkdir $TCTMP/do_pwd
    tc_break_if_bad $? "could not create directory $TCTMP/do_pwd" || return
    cd $TCTMP/do_pwd
    local actual1=`busybox pwd 2>$stderr`
    cd - &>/dev/null
    local actual2=`busybox pwd 2>>$stderr`
    echo $actual1 | grep "do_pwd" >/dev/null && \
    ! echo $actual2 | grep "do_pwd" >/dev/null
    tc_pass_or_fail $?
}

function do_printenv()
{
        tc_exec_or_break grep || return
        export local XXX=Hello
        export local YYY=Sailor
        local myenv="`busybox printenv XXX YYY`"
        echo $myenv | grep Hello &>/dev/null && \
        echo $myenv | grep Sailor &>/dev/null
        tc_pass_or_fail $? "expected \"$XXX$ $YYY\", got $myenv"
}

function do_printf()
{
        local result=`busybox printf "hello %s. float=%g\n" "sailor" "3.14159"`
        local expected="hello sailor. float=3.14159"
        [ "$result" = "$expected" ]
        tc_pass_or_fail $? "expected \"$expected\", got \"$result\""
}

function do_rdev()
{
        tc_root_or_break || return
        tc_is_fstype $TCTMP nfs && do_declined $1 "not supported on nfs mounted root systems." && return
        busybox rdev >$stdout 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        local xy=""
        xy=`busybox rdev | cut -f2 -d" "`
        [ "$xy" == "/" ]
        tc_pass_or_fail $?  "$summary3"
}

function do_realpath()
{
    touch $TCTMP/real
    ln -s $TCTMP/real $TCTMP/link
    busybox realpath $TCTMP/link >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from busybox realpath" || return
    
    grep "$TCTMP/real" $stdout &>/dev/null
    tc_pass_or_fail $? "Expected stdout to contain \"$TCTMP/real\""
}

function do_reboot()
{
	do_declined $1 "Command will reboot the machine"
}

function do_reset()
{
    busybox reset >$stdout 2>$stderr    # only test is that it doesn't crash and burn
    echo " (screen reset)"      # pretty-up the output a little
    tc_pass_or_fail $?
}

function do_rm()
{
        tc_exec_or_break ls grep || return

        touch $TCTMP/rm_me
        busybox rm $TCTMP/rm_me 2>$stderr
        local result="`ls $TCTMP/rm_me 2>&1`"
        echo $result | grep "No such file or directory" >/dev/null
        tc_pass_or_fail $? \
                "Expected file \"$TCTMP/rm_me\" to be removed, but it wasn't"
}

function do_rmdir()
{
        tc_exec_or_break mkdir ls grep || return

        mkdir -p $TCTMP/rm_me
        busybox rmdir $TCTMP/rm_me 2>$stderr
        local result="`ls $TCTMP/rm_me 2>&1`"
        echo $result | grep "No such file or directory" >/dev/null
        tc_pass_or_fail $? \
                "Expected dir \"$TCTMP/rm_me\" to be removed, but it wasn't"
}

function do_rmmod()
{
    do_insmod $1
}

function do_route()
{
    tc_exec_or_break grep || return
    busybox route -A inet 2>$stderr >$stdout
        tc_fail_if_bad $? "bad output from busybox route -A inet"  || return
    [ "$IPV6" = "yes" ] && {
        busybox route -A inet6 2>$stderr >$stdout
            tc_fail_if_bad $? "bad output from busybox route -A inet6"  || return
        cat $stdout | grep "::1/128" >/dev/null
        tc_fail_if_bad $? "Did not see ::1 info" || return
    }
    tc_pass_or_fail 0   # pass if we get this far
}

function do_runlevel()
{
	tc_exec_or_break grep || return
    tc_is_ucp && do_declined $1 "not supported on ucp systems." && return 

    busybox runlevel >$stdout 2>$stderr
    tc_fail_if_bad $? "ubexpected results" || return
    grep -q "[N,1,2,3,5] [1,2,3,5]" $stdout
	tc_pass_or_fail $? "runlevel command failed, expected=$expected but got $actual"
}

function do_seq()
{
        tc_exec_or_break grep diff cat || return

cat > $TCTMP/expected <<-EOF
3
10
17
24
31
38
45
EOF
        busybox seq 3 7 50 > $TCTMP/actual
        tc_fail_if_bad $? "busybox seq command failed" || return
        diff $TCTMP/actual $TCTMP/expected
        tc_pass_or_fail $? "busybox seq command's actual output differs from expected output"
}

function do_sha1sum()
{
    # Check if supporting utilities are available
    tc_exec_or_break  echo grep || return

    echo "1" > $TCTMP/sha1sum.txt
    echo "2" >> $TCTMP/sha1sum.txt
    echo "a" >> $TCTMP/sha1sum.txt
    echo "b" >> $TCTMP/sha1sum.txt

    busybox sha1sum  $TCTMP/sha1sum.txt >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \" sha1sum  $TCTMP/sha1sum.txt\"" || return

    local expected=fda99526e6a2267c6941d424866aaa29d6104b00
    grep -q $expected $stdout 2>$stderr
    tc_fail_if_bad $?  "Expected to see \"$expected\" in stdout" || return

    tc_info "sha1sum -c"

    busybox sha1sum  $TCTMP/sha1sum.txt >$TCTMP/sha1sum.tst 2>$stderr

    busybox sha1sum -c  $TCTMP/sha1sum.tst >$stdout 2>$stderr
    tc_fail_if_bad $?  "unexpected response from \"sha1sum -c\"" || return

    grep OK $stdout 2>$stderr
    tc_pass_or_fail $? "Expected to see \"OK\" in stdout"
}

function do_sort()
{
        # Check if supporting utilities are available
        tc_exec_or_break echo diff || return

        echo "1" > $TCTMP/sort.txt
        echo "3" >> $TCTMP/sort.txt
        echo "2" >> $TCTMP/sort.txt
        echo "c" >> $TCTMP/sort.txt
        echo "a" >> $TCTMP/sort.txt
        echo "b" >> $TCTMP/sort.txt

        busybox sort $TCTMP/sort.txt > $TCTMP/sorted.tst 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        echo "1" > $TCTMP/sort1.txt
        echo "2" >> $TCTMP/sort1.txt
        echo "3" >> $TCTMP/sort1.txt
        echo "a" >> $TCTMP/sort1.txt
        echo "b" >> $TCTMP/sort1.txt
        echo "c" >> $TCTMP/sort1.txt

        diff $TCTMP/sorted.tst $TCTMP/sort1.txt >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return
       
        busybox sort -r $TCTMP/sort.txt > $TCTMP/sort_r.tst 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

	echo "c" > $TCTMP/sorted_r.txt
        echo "b" >> $TCTMP/sorted_r.txt
        echo "a" >> $TCTMP/sorted_r.txt
        echo "3" >> $TCTMP/sorted_r.txt
        echo "2" >> $TCTMP/sorted_r.txt
        echo "1" >> $TCTMP/sorted_r.txt

        busybox sort -c $TCTMP/sorted.tst > $TCTMP/sort_r.tst 2>>$stderr
        tc_pass_or_fail $?  "$summary3"
}

function do_split()
{
        # Check if supporting utilities are available
        tc_exec_or_break  cd echo || return

        echo "1" > $TCTMP/split.txt
        echo "2" >> $TCTMP/split.txt
        echo "3" >> $TCTMP/split.txt
        echo "4" >> $TCTMP/split.txt
        echo "5" >> $TCTMP/split.txt
        echo "6" >> $TCTMP/split.txt

        cd $TCTMP >& /dev/null

        busybox split $TCTMP/split.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        if [ -s $TCTMP/xaa ]; then
                tc_fail_if_bad 0  "$summary3" || return
        else
                tc_fail_if_bad 1  "$summary3" || return
        fi

        tc_info "split -l"

        busybox split -l 2 $TCTMP/split.txt >/dev/null 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        [ -s xaa -a -s xab -a -s xac ]
        tc_pass_or_fail $?  "$summary3"
}

function do_sleep()
{
    tc_exec_or_break date || return
    local start finis delta
    declare -i start finis delta
    tc_info "Pausing for 5 seconds..."
    start=`date +%s`
    busybox sleep 5
    finis=`date +%s`
    let delta=$finis-$start
    [ $delta -ge 4 ] && [ $delta -le 10 ]
    tc_pass_or_fail $? "unexpected output. Slept for $delta seconds"
}

function do_stat()
{
        tc_exec_or_break grep || return
        touch $TCTMP/a

        local cmd="busybox stat $TCTMP/a"
        $cmd > $stdout 2>$stderr
        tc_fail_if_bad $? "unexpected results from \"$cmd\"" || return

        grep -q "Size: 0" $stdout
        tc_pass_or_fail $? "Expected to see \"Size 0\" in stdout"
}

function do_stty()
{
        tc_exec_or_break grep || return

        local link_line=$(ls -l /proc/$$/fd/0)
        local tty=${link_line##* }
        tc_info "link_line=$link_line"
        tc_info "/dev/null is $(ls -la /dev/null)"
        [ "$tty" = "/dev/null" -o "$tty" = "(deleted)" ] && {
                tc_info "$TCNAME: no available tty so skip this test"
                return 0
        }
        busybox stty -a -F $tty >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response" || return

        grep -q "speed"         <$stdout && \
        grep -q "baud"          <$stdout && \
        grep -q "rows"          <$stdout && \
        grep -q "columns"       <$stdout && \
        grep -q "intr ="        <$stdout && \
        grep -q "quit ="        <$stdout && \
        grep -q "erase ="       <$stdout && \
        grep -q "kill ="        <$stdout && \
        grep -q "eof ="         <$stdout && \
        grep -q "eol ="         <$stdout && \
        grep -q "eol2 ="        <$stdout && \
        grep -q "start ="       <$stdout && \
        grep -q "stop ="        <$stdout && \
        grep -q "susp ="        <$stdout && \
        grep -q "rprnt ="       <$stdout && \
        grep -q "werase ="      <$stdout && \
        grep -q "lnext ="       <$stdout && \
        grep -q "flush ="       <$stdout && \
        grep -q "min ="         <$stdout && \
        grep -q "time ="        <$stdout
        tc_pass_or_fail $?
}

function do_sum()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep || return

        echo "1" > $TCTMP/sum.txt
        echo "2" >> $TCTMP/sum.txt
        echo "a" >> $TCTMP/sum.txt
        echo "b" >> $TCTMP/sum.txt

        busybox sum  $TCTMP/sum.txt >$stdout 2>$stderr
        tc_fail_if_bad $? "unexpected response from \"busybox sum\""

        grep -q 23116 $stdout
        tc_pass_or_fail $? "expected to see checksum of 23116 in stdout"
}

function swap_is_on()
{
    cat /proc/swaps | grep -q "^/dev"
}

function we_have_swap_dev()
{
    grep partition /proc/swaps >$stdout 2>$stderr &&
    cat /etc/fstab | grep -q swap
}

function get_swapon_cmd()
{
    echo $names | grep -q swapon &&
    echo "busybox swapon" ||
    echo swapon
}

function get_swapoff_cmd()
{
    echo $names | grep -q swapon &&
    echo "busybox swapoff" ||
    echo swapoff
}

function do_swapoff()
{
    we_have_swap_dev || {
        do_insufficient $1 "No swap device available"
        return 0
    }

    local swapon_cmd="$(get_swapon_cmd)"
    local swapoff_cmd="$(get_swapoff_cmd)"

    # ensure swapper is on; remember original state
    # note that swapon puts non-error output in stderr
    swap_is_on && swapson=yes || {
        swapson=no
        $swapon_cmd -a  &>$stdout
        tc_fail_if_bad $? "$swapon_cmd failed" || return
    }

    # now test swapoff
    busybox swapoff -a >$stdout 2>$stderr
    tc_pass_or_fail $? "unexpected response" || return

    # restore original swap state
    [ $swapson = "yes" ] && $swapon_cmd -a
    return 0
}

function do_swapon()
{
    we_have_swap_dev || {
        do_insufficient $1 "No swap device available"
        return 0
    }

    local swapon_cmd="$(get_swapon_cmd)"
    local swapoff_cmd="$(get_swapoff_cmd)"

    # ensure swapper is off; remember original state
    swap_is_on && swapsoff=no || swapsoff=yes
    [ $swapsoff = no ] && {
        $swapoff_cmd -a  >$stdout 2>$stderr
        tc_fail_if_bad $? "$swapoff_cmd failed" || return
    }

    # now test swapon
    # NOTE: swapon puts normal output in stderr
    busybox swapon -a &>$stdout
    tc_pass_or_fail $? "unexpected results" || return

    # restore original swap state
    [ $swapsoff = yes ] && $swapoff_cmd -a
    return 0
}

function do_sync()
{
    busybox sync >$stdout 2>$stderr # only test is that it doesn't crash and burn
    tc_pass_or_fail $? "bad result"
}

function do_tac()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo diff || return

        echo "c" > $TCTMP/tac.txt
        echo "b" >> $TCTMP/tac.txt
        echo "a" >> $TCTMP/tac.txt
        echo "3" >> $TCTMP/tac.txt
        echo "2" >> $TCTMP/tac.txt
        echo "1" >> $TCTMP/tac.txt

        busybox tac $TCTMP/tac.txt >$TCTMP/tac.tst 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        echo "1" > $TCTMP/tac.txt
        echo "2" >> $TCTMP/tac.txt
        echo "3" >> $TCTMP/tac.txt
        echo "a" >> $TCTMP/tac.txt
        echo "b" >> $TCTMP/tac.txt
        echo "c" >> $TCTMP/tac.txt

        diff $TCTMP/tac.txt $TCTMP/tac.tst >& /dev/null
        tc_pass_or_fail $?  "$summary3"
}

function do_tail()
{
    local expected=$'line6\nline7\nline8\nline9\nlinea\nlineb\nlinec\nlined\nlinee\nlinef'
    local tail="`for n in 1 2 3 4 5 6 7 8 9 a b c d e f ; do
        echo line$n
    done | busybox tail`"
    [ "$tail" = "$expected" ]
    tc_pass_or_fail $? "Expected \"$expected\", got \"$tail\""
}

function do_tar()
{
        tc_exec_or_break grep ls || return

        touch $TCTMP/file1 $TCTMP/file2 $TCTMP/file3 $TCTMP/file4 $TCTMP/file5
        cd $TCTMP/

        tc_info "checking tar -c(compress)"
        busybox tar cf compress.tar file1 file2 file3 file4 file5
        tc_fail_if_bad $? "tar compression failed !"

        tc_info "checking tar -t(listing)"
        busybox tar tf $TCTMP/compress.tar | grep "file1" >$stdout 2>$stderr
        tc_fail_if_bad $? "tar listing faled !"

        tc_info "checking tar -x(extraction)"
        busybox tar xf compress.tar -C $TCTMP/ >$stdout 2>$stderr
        ls | grep -q "file1"
        tc_pass_or_fail $? "tar extraction failed !"
}

function do_taskset()
{
        local new_affinity

        # set new affinity to be 1
        busybox taskset -p 1 $$ &>/dev/null
	tc_fail_if_bad $? "unexpected response from \"busybox taskset -p 1 $$ \"" || return

        # get new affinity
        busybox taskset -p $$ >$stdout 2>$stderr
	tc_fail_if_bad $? "unexpected response from \"busybox taskset -p $$ \"" || return
        new_affinity=`taskset -p $$ |awk '{print $6}'`
	tc_fail_if_bad $? "unexpected response from \"busybox taskset -p $$ \"" || return

        [ "$new_affinity" = "1" ]
        tc_pass_or_fail $? "expect to see new affinity to be 1"
}

function do_tee()
{
    tc_exec_or_break echo || return

    local expected="Hello Sailor"
        echo "$expected" | busybox tee $TCTMP/file1 $TCTMP/file2 \
                > $TCTMP/file3 2>$stderr
        local file1=$(<$TCTMP/file1)
        local file2=$(<$TCTMP/file2)
        local file3=$(<$TCTMP/file3)
        [ "$file1" = "$expected" ] && \
        [ "$file2" = "$expected" ] && \
        [ "$file3" = "$expected" ]
        tc_pass_or_fail $? \
                "\"$file1\", \"$file2\", \"$file3\" should equal \"$expected\""
}

function TC_telnetd_inetd()
{
    local IPver=$1
    local port=$2

    local proto=tcp
    [ "$IPver" = "ipv6" ] && proto=tcp6

    cat > /etc/inetd.conf <<-EOF
telnet stream $proto nowait root busybox telnetd telnetd -i
EOF

    busybox inetd >$stdout 2>$stderr
    tc_fail_if_bad $? "could not start busybox inetd" || return

    tc_wait_for_active_port $port 10 $IPver
    tc_fail_if_bad $? "busybox inetd not listening on port $port" || return

    return 0
}

function TC_telnet()
{
    local IPver=$1
    local TC_HOSTNAME=$2
    local port=$3

    local tfile="/tmp/my$$testfile"

    tc_add_user_or_break || return

    # Create expect scritp
    local expcmd=`which expect`
    cat > $TCTMP/mtelnet <<-EOF
#!$expcmd -f
set timeout 3
set id $TC_TEMP_USER
proc abort {} { send_user "aborting\r" ;  exit 1 }
spawn busybox telnet $TC_HOSTNAME $port
expect {
    timeout abort
    "login:" { send "\$id\r" }
}
expect {
    timeout abort
    "assword:" { send "$TC_TEMP_PASSWD\r" }
}
expect {
    timeout abort
    "\$id@" { send ":> $tfile\r" }
}
expect {
    timeout abort
    "\$id@" { send "exit\r" }
}
expect eof
EOF
    chmod +x $TCTMP/mtelnet

    $TCTMP/mtelnet $tfile $port >$stdout 2>$stderr

    [ -e $tfile ]
    tc_fail_if_bad $? "telnet is not working as expected." || return

    return 0
}

function do_telnet()
{

    local port=23

    tc_exec_or_break chmod rm expect which || return
    tc_add_user_or_break || return

    TC_telnetd_inetd ipv4 $port|| return
    TC_telnet ipv4 "localhost" || return
    killall busybox
    tc_wait_for_inactive_port $port
    tc_fail_if_bad $? "busybox inetd did not give up port $port" || return

    local hostname=$(hostname)
    [ "$hostname" ] && {
        tc_info "telnet IPv4 $hostname $port"
        TC_telnetd_inetd ipv4 $port|| return
        TC_telnet ipv4 $hostname || return
        killall busybox
        tc_wait_for_inactive_port $port
        tc_fail_if_bad $? "busybox inetd did not give up port $port" || return
    }

    [ "$TC_IPV6_host_ADDRS" ] && {
        tc_info "telnet IPv6 local addr tests ($TC_IPV6_host_ADDRS) port $port"
        TC_telnetd_inetd ipv6 $port || return
        TC_telnet ipv6 "$TC_IPV6_host_ADDRS" $port || return
        killall busybox
        tc_wait_for_inactive_port $port
        tc_fail_if_bad $? "busybox inetd did not give up port $port" || return
    }
    [ "$TC_IPV6_link_ADDRS" ] && {
        tc_info "telnet IPv6 link addr tests ($TC_IPV6_link_ADDRS) port $port"
        TC_telnetd_inetd ipv6 $port || return
        TC_telnet ipv6 "$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES" $port || return
        killall busybox
        tc_wait_for_inactive_port $port
        tc_fail_if_bad $? "busybox inetd did not give up port $port" || return
    }
    [ "$TC_IPV6_global_ADDRS" ] && {
        tc_info "telnet IPv6 global addr tests ($TC_IPV6_global_ADDRS) port $port"
        TC_telnetd_inetd ipv6 $port || return
        TC_telnet ipv6 "$TC_IPV6_global_ADDRS" $port || return
        killall busybox
        tc_wait_for_inactive_port $port
        tc_fail_if_bad $? "busybox inetd did not give up port $port" || return
    }
    tc_pass
}

# This is a generic  routine to start the inetd server.
# It can also check if the services were started properly, if provided a port as $1
# Assumes that a proper inetd.conf is already created
TC_busybox_server()
{
	local port=$1

	busybox inetd >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to start tftpd" || return
	
	if [ "$1" != "" ]
	then
		tc_wait_for_active_port $port 10
		tc_fail_if_bad $? "busybox inetd failed to listen on 69"
	fi
}

# Starts the busybox tftp server
TC_busybox_tftpd()
{
	cat > /etc/inetd.conf <<_EOF
tftp dgram udp nowait root busybox busybox tftpd $@
_EOF
	TC_busybox_server 69
}
# starts the standard tftp server(read non-busybox)
TC_tftpd()
{
	cat > /etc/inetd.conf <<_EOF
tftp dgram udp nowait root in.tftpd in.tftpd $@
_EOF
	TC_busybox_server 69
}
# TFTP_* to abstract busybox / tftp clients.
# usage
#	tftp 	get remotefile localfile
#		put localfile remotefile
function tftp_tftp()
{
	local cmd=$1
	local arg1=$2
	local arg2=$3

	if [ "$cmd" == "get" ]; then
		tftp $TFTP_SERVER -c get $2 $3 >$stdout 2>$stderr
	elif [ "$cmd" == "put" ]; then
		tftp $TFTP_SERVER -c put $2 $3 >$stdout 2>$stderr
	fi
}
function tftp_busybox()
{
	local cmd=$1
	local arg1=$2
	local arg2=$3

	if [ "$cmd" == "get" ]; then
		busybox tftp -g -r $2 -l $3 $TFTP_SERVER >$stdout 2>$stderr
	elif [ "$cmd" == "put" ]; then
		busybox tftp -p -l $2 -r $3 $TFTP_SERVER >$stdout 2>$stderr
	fi
}
function do_tftpd ()
{
	TFTP_SERVER=127.0.0.1
	FTP_SERV_DIR=$TCTMP/tftp-server/

	#Check if we have a tftp client
	busybox tftp  --help 2>&1 | grep -i -q "usage: tftp"
	if [ $? -eq 0 ]; then
		# we have tftp applet in busybox
		TFTP_CMD=tftp_busybox
		tc_info "Using busybox tftp client for test"
	elif tc_executes tftp ; then
		TFTP_CMD=tftp_tftp
		tc_info "Using standard tftp client for test"
	else
		do_insufficient $1 "Could not find tftp client"
		return
	fi

	# Now setup server 
	rm -rf $FTP_SERV_DIR $TCTMP/a.txt; mkdir -p $FTP_SERV_DIR
	echo "hello"  > $FTP_SERV_DIR/1.txt

	# TEST I : 
	# Start the server in normal mode with UPLOAD Enabled
	# Verify we can upload files
	TC_busybox_tftpd -c -u root $FTP_SERV_DIR
	tc_fail_if_bad $? "Failed to start tftpd server" || return

	# Get a file from the server and compare it with the source
	$TFTP_CMD get 1.txt $TCTMP/a.txt && 
	diff -u $FTP_SERV_DIR/1.txt $TCTMP/a.txt >$stderr
	tc_fail_if_bad $? "tftp get failed" || {
		killall busybox 
		return
	}
	# Put the file to server and compare the results
	$TFTP_CMD put $TCTMP/a.txt 2.txt && diff -u $TCTMP/a.txt $FTP_SERV_DIR/2.txt >$stderr
	tc_fail_if_bad $? "tftp put failed to upload file" || {
		killall busybox 
		return
	}
	tc_info "tftpd: simple get/put test PASS"

	# We are going to restart the server
	killall busybox; sleep 1

	# TEST II:
	# Start server with restriction on upload and verify it holds
	TC_busybox_tftpd -r -u root $FTP_SERV_DIR
	tc_fail_if_bad $? "Failed to start tftpd server in restricted mode" || return

	# Put a new file on the server
	$TFTP_CMD put $TCTMP/a.txt a.txt
	if [ $? -eq 0 ]; then
		tc_info "tftp upload restriction FAIL"
		tc_fail "tftp server doesn't honour restrict upload option"
	else
		# This is stupid :). We need a clean stderr to claim PASS below. 
		tc_info "tftp upload restriction PASS" 2>$stderr
		tc_pass "All tests passed"
	fi
	
	killall busybox
	rm -rf $FTP_SERV_DIR
}
	
do_tftp()
{
	FTP_SERV_DIR=$TCTMP/tftp-server/
	mkdir -p $FTP_SERV_DIR

	# Check if we have busybox server
	busybox tftpd --help 2>&1 | grep -q -i "usage"
	if [ $? -eq 0 ];
	then
		TFTP_SERV="busybox"
		tc_info "Using the busybox TFTP Server"
		TC_busybox_tftpd -c -u root $FTP_SERV_DIR
		tc_break_if_bad $? "Failed to start busybox TFTP server" || return 
	elif [ -f /usr/sbin/in.tftpd ]
	then
		TFTP_SERV="in.tftpd"
		tc_info "Using the stand alone TFTP Server"
		TC_tftpd -c -u root -s $FTP_SERV_DIR
		tc_break_if_bad $? "Failed to start TFTP server" || return 
	else
		do_insufficient $1 "Could not find a TFTP server"
		return 
	fi
	# Dummy file for upload/download
	echo "hello world" > $FTP_SERV_DIR/hello.txt

	busybox tftp -g -r hello.txt -l $TCTMP/result.txt 127.0.0.1 >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to get file hello.txt" || return
	diff $TCTMP/result.txt $FTP_SERV_DIR/hello.txt >$stderr
	tc_fail_if_bad $? "Files do not match" || return

	tc_info "tftp get pass"
	# tftp client puts an info message in stderr about the block size 
	# feature support for server. Ignore the stderr
	busybox tftp -p -l $TCTMP/result.txt -r put.txt 127.0.0.1 &>$stdout
	tc_fail_if_bad $? "Failed to put file" || return
	diff $TCTMP/result.txt $FTP_SERV_DIR/put.txt >$stderr
	tc_fail_if_bad $? "Files do not match" || return

	tc_info "tftp put pass"

	killall $TFTP_SERV
	rm -rf $TCTMP/result.txt $TCTMP/put.txt $FTP_SERV_DIR

	tc_pass
}

function do_inetd()
{
    tc_info "$1 Tested by telnet testcase"
    return
} 

function do_test()
{
    tc_exec_or_break touch ln || return
    local tmp1=$TCTMP/xxx
    local tmp2=$TCTMP/yyy
    local cmd1="busybox test -f $fullfilename"
    local cmd2="busybox test -x $fullfilename"
    local cmd3="busybox test ! -z $fullfilename"
    local cmd4="busybox test -L $tmp2"
    touch $tmp1
    ln -s $tmp1 $tmp2
    for x in 1 2 3 4 ; do   # count must match the above cmd list
        local this_cmd_name=cmd$x
        local this_cmd="${!this_cmd_name}"
        tc_info "testing $this_cmd"
        $this_cmd >$stdout 2>$stderr
        tc_fail_if_bad $? "\"$this_cmd\" failed" || return
    done
    tc_pass
}

function do_touch()
{
    tc_exec_or_break grep || return
    busybox touch $TCTMP/touchtest &>$stderr
    ls $TCTMP | grep "touchtest" &>/dev/null
    tc_pass_or_fail $? "file not created bu touch"
}

function do_tr()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep || return

        echo "1 his" > $TCTMP/tr.txt
        echo "2 testing" >> $TCTMP/tr.txt
        echo "3 file" >> $TCTMP/tr.txt

        tc_info "testing tr"

        busybox tr his her < $TCTMP/tr.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox tr his her < $TCTMP/tr.txt | grep her >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "testing tr -d"

        busybox tr -d his < $TCTMP/tr.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox tr -d his < $TCTMP/tr.txt | grep -v his >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return

        tc_info  'testing tr -[:..:]'

        busybox tr [:lower:] [:upper:] < $TCTMP/tr.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox tr [:lower:] [:upper:] < $TCTMP/tr.txt | grep HIS >& /dev/null
        tc_pass_or_fail $?  "$summary3"
}


#
# This is untested code as busybox support is not available yet.
#   It looks wrong to me.
#   Should probably not loop through TC_IPV6_ADDRS[index], etc.
#   May need to special-case link-scope address.
function do_traceroute6()
{
    [ "$IPV6" = "yes" ] || {
        do_insufficient $1 "There is no IPV6 configured."
        return 0
    }

    local addr iface mask scope count index=0 tab=$'\t'
    count=$(tc_array_size TC_IPV6_ADDRS)
    while ((index<count)) ; do
        addr=${TC_IPV6_ADDRS[index]}
        mask=${TC_IPV6_MASKS[index]}
        iface=${TC_IPV6_IFACES[index]}
        scope=${TC_IPV6_SCOPES[index]}
        ((++index))
        scope="$scope         "
        scope=${scope/%\ */}
	# Link local addresses should contain the iface name with the addr
	[ "$scope" == "link" ] && addr="$addr%$iface"
        busybox traceroute6 $addr &>$stdout
        tc_fail_if_bad $? "bad result from busybox traceroute6 $addr (scope=$scope)" || return
    done
}

function do_traceroute()
{
    tc_exec_or_break grep || return
    busybox traceroute localhost &>$stdout
    tc_fail_if_bad $? "bad result from busybox traceroute localhost"  || return
    cat $stdout | grep ".*1.*localhost.*(127\.0\.0\.1)" >/dev/null
    tc_pass_or_fail $? "bad output from busybox traceroute localhost" \
            "Expected to see \"1  localhost (127.0.0.1)\" in stdout" || return
}

function do_true()
{
    busybox true >$stdout 2>$stderr
    tc_pass_or_fail $? "\"true\" returned $?"
}

function do_tty()
{
    tc_exec_or_break grep || return
    busybox tty 2>$stderr >$stdout
    grep "/dev" $stdout &>/dev/null || \
    grep "not a tty" $stdout &>/dev/null
    tc_pass_or_fail $? "unexpected results"
}

function do_ttysize()
{
    tc_exec_or_break stty awk || return

    terminal_size=`stty size | awk '{print $2 " " $1}'`
    if [ -z "$terminal_size" ]; then
        tc_info "No active Sessions/Terminals Found"
        return
    fi

    bb_terminal_size=`busybox ttysize`

    [ "$bb_terminal_size" = "$terminal_size" ]
    tc_pass_or_fail $? "ttysize command failed expected=$terminal_size actual=$bb_terminal_size"
}

function do_umount()
{
    tc_root_or_break || return

    [ "$do_umount_ok" = "yes" ]
    tc_break_if_bad $? "can't test umount since mount was not run (or failed)" || return

    local my_loop_dev=$(cat /proc/mounts | grep $TCTMP/bb_mnt)
    [ "$my_loop_dev" ] && set $my_loop_dev && my_loop_dev=$1
    busybox umount $TCTMP/bb_mnt >$stdout 2>$stderr
    local result="`cat $TCTMP/bb_mnt/status 2>/dev/null`"
    [ "$my_loop_dev" ] && losetup -d $my_loop_dev
    expected=""
    [ "$result" = "$expected" ]
    tc_pass_or_fail $? "$TCTMP/bb_mount.img not unmounted"
}

function do_uname()
{
    tc_exist_or_break "/proc/sys" || return
    local ostype=`cat /proc/sys/kernel/ostype`
    local hostname=`cat /proc/sys/kernel/hostname`
    local osrelease=`cat /proc/sys/kernel/osrelease`
    local version=`cat /proc/sys/kernel/version`
    local expected="$ostype $hostname $osrelease $version"
    local actual=`busybox uname -a 2>$stderr`
    echo $actual | grep "$expected" >/dev/null
    tc_pass_or_fail $? "expected \"$expected\", got \"$actual\""
}

function do_uncompress()
{
    cp $BB_DIR/compress_test_file.Z $TCTMP/
    busybox uncompress $TCTMP/compress_test_file.Z
    tc_fail_if_bad $? "Unexpected response from \"busybox uncompress compress_test_file.Z\"" || return
    
    grep -q "busybox uncompress applet." $TCTMP/compress_test_file
    tc_pass_or_fail $? "Expected to see \"busybox uncompress applet.\" in stdout"
}

function do_unexpand()
{
        # Check if supporting utilities are available
        tc_exec_or_break grep cat echo || return

        echo "                16" > $TCTMP/unexpand.txt
        busybox unexpand $TCTMP/unexpand.txt >$TCTMP/unexpand.tst 2>>$stderr
        tc_pass_or_fail $?  "$summary2"
}

function do_uniq()
{
        # Check if supporting utilities are available
        tc_exec_or_break  echo grep || return

        echo "a aple" > $TCTMP/uniq.txt
        echo "b banana" >> $TCTMP/uniq.txt
        echo "b banana" >> $TCTMP/uniq.txt
        echo "c cat" >> $TCTMP/uniq.txt
        echo "c cat" >> $TCTMP/uniq.txt
        echo "c cat" >> $TCTMP/uniq.txt

        busybox uniq $TCTMP/uniq.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox uniq $TCTMP/uniq.txt | grep -c cat | grep 1  >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "uniq -u"

        busybox uniq -u $TCTMP/uniq.txt >/dev/null 2>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox uniq -u $TCTMP/uniq.txt | grep -v cat  >& /dev/null
        tc_fail_if_bad $?  "$summary3" || return

        tc_info "uniq -c"

        busybox uniq -c $TCTMP/uniq.txt >/dev/null 2>>$stderr
        tc_fail_if_bad $?  "$summary2" || return

        busybox uniq -c $TCTMP/uniq.txt | grep 3  >& /dev/null
        tc_pass_or_fail $?  "$summary3"
}

function do_uptime()
{
    tc_exec_or_break grep || return
    busybox uptime | grep "load average:" >$stdout 2>$stderr 
    tc_pass_or_fail $? "unexpected results"
}

function do_wc()
{
    local count expected
    declare -i count expected
    expected=0
    for i in $names ; do
        let expected+=1
    done
    count=`echo $names | busybox wc -w`
    [ $count -eq $expected ]
    tc_pass_or_fail $? "expected $original_total, got $count"
}

function do_which()
{
    tc_exec_or_break chmod || return
    cat > $TCTMP/xxx.sh <<-EOF
#!$SHELL
true
EOF
    chmod +x $TCTMP/xxx.sh

    local command=$TCTMP/xxx.sh
    which $command &>$TCTMP/expected
    busybox which $command &>$stdout
    tc_fail_if_bad $? "busybox which gave unexpected results" || return

    local expected=$(<$TCTMP/expected)
    local actual=$(<$stdout)
    [ "$expected" = "$actual" ]
    tc_pass_or_fail $? "busybox's which gave different results from the system's which" \
        "$command" \
        "expected: $expected" \
        "     got: $actual"
}

function do_who()
{
  tc_exec_or_break grep tr || return
	cat >> $TCTMP/genkey.sh <<-EOF
	#!/usr/bin/expect -f
	set timeout 5
	proc abort {} { exit 1 }
	spawn ssh-keygen
	expect "Enter file in which to save the key (/root/.ssh/id_rsa):"
	send "\r"
	expect "Enter passphrase (empty for no passphrase):"
	send "\r"
	expect "Enter same passphrase again:"
	send "\r"
	expect eof
	EOF

  chmod +x $TCTMP/genkey.sh

  $TCTMP/genkey.sh 
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  ssh -tttttttt root@localhost busybox who > $TCTMP/result

  rm -rf /root/.ssh/id_rsa*

  cat $TCTMP/result | tr -s ' ' &> $TCTMP/formatted_result
  grep -o "[[:alnum:]_]\+[[:space:]]\+[[:alnum:]_]\+[[:punct:]]\?[[:alnum:]_]\+[[:space:]]\+[[:alnum:]_]\+[[:punct:]]\+[[:alnum:]_]\+[[:space:]]\+[[:alnum:]_]\+[[:space:]]\+[[:alnum:]_]\+[[:space:]]\+[[:alnum:]_]\+[[:punct:]]\+[[:alnum:]_]\+[[:punct:]]\+[[:alnum:]_]\+" $TCTMP/formatted_result
  tc_pass_or_fail $? "who command failed !"
}

function do_whoami()
{
    tc_root_or_break || return
    tc_exec_or_break su || return
    tc_add_user_or_break || return
    echo "busybox whoami" | su $TC_TEMP_USER > $TCTMP/user
    local actual="`cat $TCTMP/user`"
    [ "$actual" = "$TC_TEMP_USER" ]
    tc_pass_or_fail $? "wrong userid returned" \
        "expected \"$TC_TEMP_USER\"" \
        "got \"$actual\""
}

function do_yes()
{
    echo > $TCTMP/read <<- EOF
#!$SHELL
read a; read b; read c; read d; read e
[ "$a" = "sailor" ] && \
[ "$b" = "sailor" ] && \
[ "$c" = "sailor" ] && \
[ "$d" = "sailor" ] && \
[ "$e" = "sailor" ] && exit 0
exit 1
EOF
    busybox yes "sailor" | source $TCTMP/read
    tc_pass_or_fail $? "read did not get input from yes"
}

function do_zcat() {
    local cmd="busybox zcat $BB_DIR/compress_test_file.Z"
    $cmd >$stdout 2>$stderr
    tc_fail_if_bad $? "unexpected response from \"$cmd\"" || return
    grep -q "This is a file for testing the busybox uncompress applet." $stdout
    tc_pass_or_fail $? "miscompare of stdout"
}

VT=-1
function find_vt() {
	tc_executes fuser && {
		for ((i=63; i >= 1; i--))
		do
                        ls /dev/tty$i &>/dev/null || continue # doen't exist
                        dd if=/dev/null of=/dev/tty$i bs=1 count=0 &>/dev/null || continue # not an active tty device
                        fuser /dev/tty$i &>/dev/null && continue # it's in use
                        VT=$i # Found one! Active and available.
                        tc_info "using /dev/tty$VT"
                        return
		done
	}
	VT=-1
}


function do_openvt() {
    tc_get_os_arch
    [ "$TC_OS_ARCH" = "ppcnf" ] && do_declined $1 "ppcnf does not have virtual terminals" && return
	find_vt
	[ "$VT" = "-1" ] && {
		do_insufficient $1 "Unable to find free Virtual Terminal"
		return
	}

	busybox openvt -w -f -c $VT >$stdout 2>$stderr -- sh -c "ls -l /proc/self/fd/0 > $TCTMP/ps.out" 
	tc_fail_if_bad $? "openvt failed" || return
	grep -q tty$VT $TCTMP/ps.out
	tc_pass_or_fail $? "Could not find tty$VT in command output" \
	"========= Command output =======" \
	"$(< $TCTMP/ps.out)"

	tc_executes deallocvt && deallocvt  $VT 2>/dev/null >/dev/null
}

function do_deallocvt() {
    tc_get_os_arch
    [ "$TC_OS_ARCH" = "ppcnf" ] && do_declined $1 "ppcnf does not have virtual terminals" && return
    find_vt
    [ "$VT" = "-1" ] && {
        do_insufficient $1 "Unable to find free Virtual Terminal"
        return
    }

    busybox openvt -w -f -c $VT >$stdout 2>$stderr -- ps
    tc_fail_if_bad $? "Unable to open the VT" || return
    busybox deallocvt $VT 2>$stderr >$stdout
    tc_pass_or_fail $? "deallocvt failed"
}

function do_watch() {
    local cmd=date
    busybox watch $cmd > $stdout 2>$stderr &
    local killme=$!
    tc_info "give watch 4 seconds to run"
    tc_wait_for_pid $killme || return
    sleep 4
    kill $killme || kill -9 $killme
    tc_wait_for_no_pid $killme || return
    local count=$(grep -- "$cmd" $stdout | wc -l)
    ((count > 1))
    tc_pass_or_fail $? "watch did not display output at least twice. Saw $count"
}

function do_su() {
    expected="I WAS HERE"
    tc_add_user_or_break || return
    busybox su -c "echo $expected > myfile.txt" - $TC_TEMP_USER
    grep -q "$expected" /home/$TC_TEMP_USER/myfile.txt
    tc_pass_or_fail $? "could not su to $TC_TEMP_USER"
}

SPACES="                "
function do_unsupported()
{
    tc_conf "${SPACES}Not yet implemented."
    (( unsupported+=1))
    return 0
}

function do_declined()
{
    tc_conf "${SPACES}Declined. $*"
    (( untested+=1))
    return 0
}

function do_insufficient()
{
    tc_conf "${SPACES}Insufficient system configuration or resources. $*"
    (( insufficient+=1))
    return 0
}


################################################################################
# main
################################################################################

# get applets to test from /etc/busybox.links or busybox output
if [ -f /etc/busybox.links ] ; then
    while read n junk ; do
        [ "$n" == "#" ] && continue
        names="$names ${n##*/}" # append basename of link
    done < /etc/busybox.links
else
    go=""
    while read line; do
        [ "${line/defined functions/}" != "$line" ] && go=go && continue
        [ "$go" ] && names="$names ${line//,/}"
    done < <(busybox) 
fi

[ "$*" ] && names="$@"

((TST_TOTAL=0))
[ "$names" ] && {
    set $names
    TST_TOTAL=$#
}
(( TST_TOTAL+=1 ))

tc_setup

installation_check || exit

# in case needed
# see bug 64374, comment #3
#BBOX_VER=$(set $(busybox | grep "BusyBox v") ; echo ${2#v})
#read major minor micro < <(IFS="."; set $BBOX_VER ; echo $1 $2 $3; )
#((BBOX_VER=major*10000+minor*100))  # ignore micro

#
# run tests against all supported (or requested) busybox applets
#
savedPWD=$(pwd)
for n in $names ; do
    cd $savedPWD                # in case some self-centered test rudely modifies the PWD
    [ "$n" == "[" ] && n=LBR
    [ "$n" == "[[" ] && n=LBR_LBR
    tc_register $n
    tc_executes do_$n &> /dev/null || { do_unsupported $n ; continue ; }
    do_$n $n || FAILS="$FAILS $n"
done

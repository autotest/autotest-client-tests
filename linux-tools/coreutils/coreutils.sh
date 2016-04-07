#!/bin/bash
###########################################################################################
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
# File :	coreutils.sh
#
# Description:	Test the functions provided by sh-utils.
#
# Author:	Robert Paulsen, rpaulsen@us.ibm.com

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

################################################################################
# global variables
################################################################################
exp_path=`which expect`
host="localhost"
prompt=':::'

# commands to be tested
names="
	 [ basename date echo false pwd sleep stty su true uname chroot \
	dirname env expr factor groups id logname nice nohup pathchk pinky \
	printenv printf seq tee test tty users who whoami yes\

	cat comm expand head nl pr sort tsort wc csplit fmt \
	join od split tail unexpand cksum cut fold md5sum \
	paste sha1sum sum tr uniq ptx \

	cp mkdir chgrp chmod chown dd df du kill ln ls rm rmdir touch mv uptime"

[ "$*" ] && names="$@"

TST_TOTAL=0
[ "$names" ] && {
	set $names
	TST_TOTAL=$#
}
	

################################################################################
# utility functions
################################################################################

#
# local cleanup
#

function tc_local_setup()
{
	tc_root_or_break || return 
	[ "localhost.localdomain" = "$(hostname)" ] &&  hostname localhost
        return 0

}

function tc_local_cleanup()
{
	[ "$killme" ] && {
		ps -ef $killme &>/dev/null && { kill $killme || kill -9 $killme ; }
	}
}

################################################################################
# the testcase functions
################################################################################

function do_basename()
{
	tc_exec_or_break || return
	local actual="`basename $0 2>$stderr`"
	[ "$actual" = "${0##*/}" ]
	tc_pass_or_fail $? "basname expected \"${0##*/}\" but got \"$actual\""
}

function do_date()
{
	tc_exec_or_break sleep || return
	local -i start finis delta
	start=`date +%s 2>$stderr`
	tc_info "Pausing for 5 seconds..."
	sleep 5
	finis=`date +%s 2>$stderr`
	let delta=$finis-$start
	[ $delta -ge 4 ] && [ $delta -le 10 ]
	tc_pass_or_fail $? "Expected $finis to be between 4 and 10 seconds greater than $start but was $delta"
}

function do_echo()
{
	tc_exec_or_break grep || return
	echo "hello sailor" 2>$stderr | grep "hello sailor" >/dev/null
	tc_pass_or_fail $?
}

function do_false()
{
	! false 2>$stderr
	tc_pass_or_fail $?
}

function do_pwd()
{
	tc_exec_or_break mkdir grep || return
	mkdir -p $TCTMP/do_pwd
	cd $TCTMP/do_pwd
	local actual1=`pwd 2>$stderr`
	cd - &>/dev/null
	local actual2=`pwd 2>>$stderr`
	echo $actual1 | grep -q "do_pwd" &&
	! echo $actual2 | grep -q "do_pwd" 
	tc_pass_or_fail $?
}

function do_sleep()
{
	tc_exec_or_break date || return
	local -i start finis delta
	tc_info "Pausing for 5 seconds..."
	start=`date +%s`
	sleep 5 2>$stderr
	finis=`date +%s`
	let delta=$finis-$start
	[ $delta -ge 4 ] && [ $delta -le 6 ]
	tc_pass_or_fail $?
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
	stty -a -F $tty >$stdout 2>$stderr 
	tc_fail_if_bad $? "unexpected response" || return

	grep -q "speed"		<$stdout && \
	grep -q "baud"		<$stdout && \
	grep -q "rows"		<$stdout && \
	grep -q "columns"	<$stdout && \
	grep -q "line"		<$stdout && \
	grep -q "intr ="	<$stdout && \
	grep -q "quit ="	<$stdout && \
	grep -q "erase ="	<$stdout && \
	grep -q "kill ="	<$stdout && \
	grep -q "eof ="		<$stdout && \
	grep -q "eol ="		<$stdout && \
	grep -q "eol2 ="	<$stdout && \
	grep -q "start ="	<$stdout && \
	grep -q "stop ="	<$stdout && \
	grep -q "susp ="	<$stdout && \
	grep -q "rprnt ="	<$stdout && \
	grep -q "werase ="	<$stdout && \
	grep -q "lnext ="	<$stdout && \
	grep -q "flush ="	<$stdout && \
	grep -q "min ="		<$stdout && \
	grep -q "time ="	<$stdout 
	tc_pass_or_fail $?
}

function do_su()
{
	tc_root_or_break || return
	tc_exec_or_break awk pwd sed || return
	echo -n "" > $stderr
	# create a temp user
	tc_add_user_or_break &>/dev/null || return
	# check that "su TC_TEMP_USER" switches to user
	echo "echo \$USER" | su $TC_TEMP_USER &>$TCTMP/output
	local user_name=$(<$TCTMP/output)
	[ "$user_name" = "$TC_TEMP_USER" ]
	tc_fail_if_bad $? "expected userid \"$TC_TEMP_USER\", got \"$user_name\"" || return
	
	# check that "su TC_TEMP_USER" stays in original pwd
	echo -n "" > $stderr
	echo "echo `pwd`" | su $TC_TEMP_USER &>$TCTMP/output
	local temp_pwd=$(<$TCTMP/output)
	local real_pwd="`pwd`"
	echo $temp_pwd | grep $real_pwd >$stdout 2>$stderr
	tc_fail_if_bad $? "expected directory \"$real_pwd\", got \"$temp_pwd\"" || return

	# check that "su - TC_TEMP_USER" switches to user
	echo -n "" > $stderr
	echo "echo \$USER" | su - $TC_TEMP_USER &>$TCTMP/output
	local user_name=`awk '$1!="hostname:" {print}' $TCTMP/output`
	echo $user_name | grep $TC_TEMP_USER >$stdout 2>$stderr
	tc_fail_if_bad $? "expected userid \"$TC_TEMP_USER\", got \"$user_name\"" || return

	# check that "su - TC_TEMP_USER" sets new pwd
	# This causes TC_TEMP_USER to create a file in $HOME and immediately
	# exit back to root. Root then checks that the file has the correct contents.
	# If so, "su - TC_TEMP_USER" is deemed to have succeeded.
	echo -n "" > $stderr
	echo "echo hello > hello.txt" | su - $TC_TEMP_USER 2>/dev/null
	local home=`sed -n "/^\$TC_TEMP_USER:/p" /etc/passwd | cut -d':' -f 6`
	local actual="$(<$home/hello.txt)"
	[ "$actual" = "hello" ]
	tc_pass_or_fail $? "expected \"hello\", got \"$actual\""
}

function do_true()
{
	true 2>$stderr
	tc_pass_or_fail $? "\"true\" did not return \"0\""
}

function do_uname()
{
	tc_exist_or_break "/proc/sys" || return
	local ostype=$(</proc/sys/kernel/ostype)
	local hostname=$(</proc/sys/kernel/hostname)
	local osrelease=$(</proc/sys/kernel/osrelease)
	local version=$(</proc/sys/kernel/version)
	local expected="$ostype $hostname $osrelease $version"
	local actual=`uname -a 2>$stderr`
	echo $actual | grep "$expected" >/dev/null
	tc_pass_or_fail $? "expected=$expected, actual=$actual"
}

function do_LBR()	# left square bracket
{
	tc_exec_or_break grep || return
	"[" 2>&1 | grep "\[: missing" >/dev/null
	tc_pass_or_fail $? 
}

function do_chroot_shell_no_ldd()
{
	local SHELL=$1

	if tc_is_busybox $SHELL ; then
		cp $(which busybox) $TCTMP/fakeroot/bin
		ln -s $TCTMP/fakeroot/bin/busybox $TCTMP/fakeroot/$SHELL
	else
		cp $SHELL $TCTMP/fakeroot/$SHELL
	fi

	cp /lib/libreadline.so.* $TCTMP/fakeroot/lib
	cp /lib/libhistory.so.* $TCTMP/fakeroot/lib
	cp /lib/libncurses.so.* $TCTMP/fakeroot/lib
	cp /lib/libdl.so.* $TCTMP/fakeroot/lib
	cp /lib/libc.so.* $TCTMP/fakeroot/lib
	cp /lib/ld*.so.* $TCTMP/fakeroot/lib

	chroot $TCTMP/fakeroot $SHELL /doit >$stdout 2>$stderr
	grep "Hello Sailor" $TCTMP/fakeroot/hello.txt >/dev/null
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

function do_chroot_shell_ldd()
{
	SHELL=$1

	if tc_is_busybox $SHELL ; then
		cp $(which busybox) $TCTMP/fakeroot/bin
		ln -s $TCTMP/fakeroot/bin/busybox $TCTMP/fakeroot/$SHELL
	else
		cp $SHELL $TCTMP/fakeroot/$SHELL
	fi

	ldd $SHELL > $TCTMP/libs
	while read lib1 junk lib2 junk ; do
		[ -f $lib2 ] && cp $lib2 $TCTMP/fakeroot/lib ||
			cp $lib1 $TCTMP/fakeroot/lib
	done < $TCTMP/libs
	chroot $TCTMP/fakeroot $SHELL /doit >$stdout 2>$stderr
	tc_fail_if_bad $? "chroot failed" || return
	grep "Hello Sailor"  $TCTMP/fakeroot/hello.txt >$stdout 2>$stderr
	tc_pass_or_fail $? "did not execute script in chrooted jail"
}

function do_chroot_no_shell()
{
	tc_info "Without ash or sh this test simply"
	tc_info "checks that chroot returns the proper"
	tc_info "error message."
	local result=`chroot $TCTMP xyz 2>&1`
	local exp
	exp="chroot: cannot execute xyz: No such file or directory"
	[ "$result" = "$exp" ]
	tc_pass_or_fail $? "bad result: \"$result\""
}

function do_chroot() {
	tc_exec_or_break chmod mkdir cat || return
	mkdir -p $TCTMP/fakeroot/bin
	mkdir -p $TCTMP/fakeroot/usr/bin
	mkdir -p $TCTMP/fakeroot/lib
	ln -s lib $TCTMP/fakeroot/lib64
	cat > $TCTMP/fakeroot/doit <<-EOF
		#!$SHELL
		# something to run in fakeroot
		echo "Hello Sailor" > hello.txt
	EOF
	chmod +x $TCTMP/fakeroot/doit

	local ldd_path=$(which ldd 2>/dev/null)
	local bash_path=$(which bash 2>/dev/null)
	local ash_path=$(which ash 2>/dev/null)
	local static_ash_path=$(which ash.static 2>/dev/null)

	if [ "$ldd_path" ] ; then
		if [ "$bash_path" ] ; then
			if ldd $bash_path &>/dev/null ; then
				do_chroot_shell_ldd $bash_path 2>/dev/null
				return
			fi
		fi
		if [ "$ash_path" ] ; then
			if ldd $ash_path &>/dev/null ; then
				do_chroot_shell_ldd $ash_path 2>/dev/null
				return
			fi
		fi
		return 0
	fi
	if [ "$bash_path" ] ; then
		do_chroot_shell_no_ldd $bash_path
		return
	elif [ "$ash_path" ] ; then
		do_chroot_shell_no_ldd $ash_path
		return
	elif [ "$static_ash_path" ] ; then
		do_chrot_shell_no_ldd $static_ash_path
		return
	fi
	do_chroot_no_shell
}

function do_dirname()
{
	tc_exec_or_break touch mkdir || return
	mkdir -p $TCTMP/dir
	touch $TCTMP/dir/file
	local dirname=`dirname $TCTMP/dir/file 2>$stderr`
	[ "$TCTMP/dir" = "$dirname" ]
	tc_pass_or_fail $?
}

function do_env()
{
	tc_exec_or_break grep || return
	export XXX="hello sailor"
	env 2>$stderr | grep "XXX" | grep "hello sailor" > /dev/null
	tc_pass_or_fail $?
}

function do_expr()
{
	tc_exec_or_break || return
	local val1=`expr 7 \* 6 2>>$stderr`
	local exp1=42
	local val2=`expr length "hello sailor" 2>>$stderr`
	local exp2=12
	local val3=`expr "abc" : "a\(.\)c" 2>$stderr`
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

function do_factor()
{
	tc_exec_or_break || return
	local exp="111: 3 37"
	local act=`factor 111 2>$stderr`
	local failure
	[ "$exp" = "$act" ] || failure="expected $exp, got $act"
	[ -z "$failure" ]
	tc_pass_or_fail $? "$failure"
}

function do_groups()
{
	tc_exec_or_break grep cat sort uniq || return

	# put expected groups in file 
	cut -f1 -d: /etc/group | grep $USER > $TCTMP/groups
	local defgid="$(grep \"^$USER\" /etc/passwd | cut -f4 -d:)"
	cut -f1 -d: /etc/group | grep ":$defgid:" >> $TCTMP/groups
	sort $TCTMP/groups | uniq > $TCTMP/expected
	local expected="$(<$TCTMP/expected)"

	local temp="`groups 2>$stderr`"
	local g
	local -i i=0
	cat /dev/null > $TCTMP/groups2
	for g in $temp ; do
		#let ++i
		#[ $i -lt 3 ] && continue	# skip uid and colon
		echo $g >> $TCTMP/groups2	# multiline for sorting
	done
	grep $expected $TCTMP/groups2 >$stdout 2>$stderr
	tc_pass_or_fail $? "expected \"$expected\" "
}

function do_id()
{
	tc_exec_or_break echo || return
	local actual=`id $USER 2>$stderr`
	tc_fail_if_bad $? "unexpected results" "rc=$?"
#
	local actual1=`echo $actual | grep "($USER)"`
	local actual2=`echo $actual | grep uid=`
	local actual3=`echo $actual | grep gid=`
	local actual4=`echo $actual | grep groups=`
	[ "$actual1" ] && \
	[ "$actual2" ] && \
	[ "$actual3" ]
	tc_pass_or_fail $? \
		"expected \"($USER)\", \"uid=\", \"gid=\", got \"$actual\"" 
}

function do_logname()
{
	tc_exec_or_break wc echo || return
	local actual=`logname 2>&1`
	local words
	declare -i words=`echo $actual | wc -w`
	[ $words -eq 1 ] || [ "$actual" = "logname: no login name" ]
	tc_pass_or_fail $? "expected a username or \"no login name\", got \"$actual\""
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
	nice -n +10 $TCTMP/niceme$$ >$stdout 2>$stderr &
	tc_fail_if_bad $? "unexpected response from nice -n +10 $TCTMP/niceme$$" || return

	tc_wait_for_file $TCTMP/killme 10 size
	tc_fail_if_bad $? "nice did not start command $TCTMP/niceme$$" || return

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
	
	kill $killme || kill -9 $killme	# kill the niced process
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
		echo \$\$	# my pid
		while : ; do
			sleep 1
		done
	EOF
	chmod +x $TCTMP/hupme$$
	chmod a+rwx $TCTMP

	echo "nohup $TCTMP/hupme$$ &>$TCTMP/hupout &" | su -l $TC_TEMP_USER 2>/dev/null
	tc_wait_for_file $TCTMP/hupout 10 size
	tc_fail_if_bad $? "no pid from $TCTMP/hupme$$" || return

	# send hup signal
	local killme=$(<$TCTMP/hupout)
	kill -1 $killme &>/dev/null
	tc_info "We are hoping that pid $killme does NOT go away"
	! tc_wait_for_no_pid $killme 5
	tc_pass_or_fail $? "Process died but shouldn't have"  || return
	kill $killme || kill -9 $killme	# kill the nohupped process
        unset killme
	local procpid=`pgrep -u  $TC_TEMP_USER`
	[ "$procpid" ] && { kill -9 $procpid &>/dev/null ; }
	tc_del_user_or_break &>/dev/null

}

function do_pathchk()
{
	tc_root_or_break || return
	tc_exec_or_break su mkdir chmod || return
	tc_add_user_or_break &>/dev/null || return
	mkdir $TCTMP/pathchk
	touch $TCTMP/pathchk/xxx
	chmod a-x $TCTMP/pathchk
	local result=`echo "pathchk $TCTMP/pathchk/xxx 2>&1" | \
		su $TC_TEMP_USER`
	echo $result | grep "$TCTMP/pathchk" >/dev/null &&
	( echo $result | grep "is not searchable" >/dev/null ||
	  echo $result | grep "Permission denied" >/dev/null )
	tc_pass_or_fail $? "$result"
	tc_del_user_or_break &>/dev/null
}

function do_pinky()
{
        tc_add_user_or_break || return

	tc_exec_or_break grep expect cat su ssh sshd chmod chown || return

	echo "PS1=$prompt" >> /home/$TC_TEMP_USER/.bashrc
	chown -R $TC_TEMP_USER $TCTMP

	# create expect file to create a login session to a machine
	rm -rf /home/$TC_TEMP_USER/.ssh/
	cat > $TCTMP/exp_script <<-EOF
		#!$exp_path -f
		set timeout 60
		proc abort1 {} { exit 1 }
		proc abort2 {} { exit 2 }
		proc abort3 {} { exit 3 }
		proc abort4 {} { exit 4 }
		proc abort5 {} { exit 5 }
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort1
			"$prompt" { send "ssh $TC_TEMP_USER@$host\r" }
		}
		expect {
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout abort2
			"$TC_TEMP_USER@$host's password:" { send "$TC_TEMP_PASSWD\r" }
		}
		expect {
			timeout abort3
                        "$prompt" { send "pinky > $TCTMP/file5 \r" }
                }
		sleep 5
		expect {
			timeout abort4
			"$prompt" { send "exit\r" }
		}
		sleep 2
		expect {
			timeout abort5
			"$prompt" { send "exit\r" }
		}
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/exp_script
	
	$TCTMP/exp_script >$stdout 2>$stderr
	tc_fail_if_bad $? "ssh failed." || return
        tc_exec_or_break grep || return
	cat $TCTMP/file5 2>$stderr | grep "Login" >/dev/null
	tc_pass_or_fail $? "pinky test Failed"
}

function do_printenv()
{
	tc_exec_or_break grep || return
	export local XXX=Hello
	export local YYY=Sailor
	local myenv="`printenv XXX YYY`"
	echo $myenv | grep Hello &>/dev/null && \
	echo $myenv | grep Sailor &>/dev/null
	tc_pass_or_fail $? "expected \"$XXX$ $YYY\", got $myenv"
}

function do_printf()
{
	local result=`printf "hello %s. float=%g\n" "sailor" "3.14159"`
	local expected="hello sailor. float=3.14159"
	[ "$result" = "$expected" ]
	tc_pass_or_fail $? "expected \"$expected\", got \"$result\""
}

function do_seq()
{
	local arg1="-s: -f%g 3 7 50"
	local arg2="-s: -f%f 3 7 50"
	local arg3="-s: -f%e 3 7 50"
	local exp1="3:10:17:24:31:38:45"
	local exp2="3.000000:10.000000:17.000000:24.000000:31.000000:38.000000:45.000000"
	local exp3="3.000000e+00:1.000000e+01:1.700000e+01:2.400000e+01:3.100000e+01:3.800000e+01:4.500000e+01"
	local act1=""
	local act2=""
	local act3=""
	local failed=""
	for x in 1 2 3 ; do
		eval act$x=$(eval seq \$arg$x)
		if ! eval [ "\$exp$x" = "\$act$x" ] ; then
			eval local expected="\$exp$x"
			eval local actual="\$act$x"
			local failed="$failed expected $expected, got $actual"
			break
		fi
	done
	[ -z "$failed" ]
	tc_pass_or_fail $? "$failed"
}

function do_tee()
{
	tc_exec_or_break echo || return
	local expected="Hello Sailor"
	echo "$expected" | tee $TCTMP/file1 $TCTMP/file2 \
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

function do_test
{
	local fullfilename=$0
	tc_exec_or_break touch ln || return
	local tmp1=$TCTMP/xxx
	local tmp2=$TCTMP/yyy
	local cmd1="test -f $fullfilename"
	local cmd2="test -x $fullfilename"
	local cmd3="test ! -z $fullfilename"
	local cmd4="test -L $tmp2"
	touch $tmp1
	ln -s $tmp1 $tmp2
	local failed=""
	for x in 1 2 3 4 ; do	# count must match the above cmd list
		eval \$cmd$x 2>$stderr || eval failed="\" \$cmd$x failed\""
		[ "$failed" ] && break
	done
	[ -z "$failed" ]
	tc_pass_or_fail $? "$failed"
}

function do_tty()
{
	tc_exec_or_break grep || return
	tty 2>$stderr | grep "/dev" &>/dev/null || \
	tty 2>$stderr | grep "not a tty" &>/dev/null
	tc_pass_or_fail $?
}

function do_users()
{
	tc_exec_or_break grep cut || return
	local name=`users 2>$stderr | cut -f1 -d" "`
	grep "$name" /etc/passwd &>/dev/null
	tc_pass_or_fail $? "users returned \"$name\" which is not a valid user"
}

function do_who()
{
        tc_add_user_or_break || return

        tc_exec_or_break expect cat su ssh chmod chown || return
 
	echo "PS1=$prompt" >> /home/$TC_TEMP_USER/.bashrc
	chown -R $TC_TEMP_USER $TCTMP

	# create expect file to create a login session to a machine
	rm -rf /home/$TC_TEMP_USER/.ssh/
	cat > $TCTMP/exp_script <<-EOF
		#!$exp_path -f
		set timeout 30
		proc abort1 {} { exit 1 }
		proc abort2 {} { exit 2 }
		proc abort3 {} { exit 3 }
		proc abort4 {} { exit 4 }
		proc abort5 {} { exit 5 }
		proc abort6 {} { exit 6 }
		proc abort7 {} { exit 99}
		spawn su - $TC_TEMP_USER
		expect {
			timeout abort1
			"$prompt" { send "ssh $TC_TEMP_USER@$host\r" }
		}
		expect {
			timeout abort2
			"(yes/no)?" { send "yes\r" }
		}
		expect {
			timeout abort3
			"$TC_TEMP_USER@$host's password:" { send "$TC_TEMP_PASSWD\r" }
		}
		expect {
			timeout abort4
                        "$prompt" { send "who > $TCTMP/file4 \r" }
                }
		sleep 5
		expect {
			timeout abort5
			"$prompt" { send "exit\r" }
		}
		sleep 2
		expect {
			timeout abort6
			"$prompt" { send "exit\r" }
		}
		send_user "all done\n"
	EOF
	chmod +x $TCTMP/exp_script
	
	$TCTMP/exp_script >$stdout 2>$stderr
	tc_fail_if_bad $? "ssh failed."  || return

	tc_exec_or_break grep cut || return
	local name=`cat $TCTMP/file4 2>$stderr | cut -f1 -d" "`
	grep "$name" /etc/passwd &>/dev/null
	tc_pass_or_fail $? "who returned \"$name\" which is not a valid user"
}

function do_whoami()
{
	tc_root_or_break || return
	tc_exec_or_break echo su || return
	tc_add_user_or_break &>/dev/null || return
	echo "whoami" | su $TC_TEMP_USER > $TCTMP/user
	local actual="$(<$TCTMP/user)"
	[ "$actual" = "$TC_TEMP_USER" ]
	tc_pass_or_fail $? "expected \"$TC_TEMP_USER\", got \"$actual\""
	tc_del_user_or_break &>/dev/null
}

function do_yes()
{
	tc_exec_or_break echo || return
	echo > $TCTMP/read <<-EOF
		#!$SHELL
		read a; read b; read c; read d; read e
		[ "$a" = "sailor" ] && \
		[ "$b" = "sailor" ] && \
		[ "$c" = "sailor" ] && \
		[ "$d" = "sailor" ] && \
		[ "$e" = "sailor" ] && exit 0
		exit 1
	EOF
	yes "sailor" | source $TCTMP/read
	tc_pass_or_fail $?
}

function do_unknown() {
	tc_pass_or_fail 0 "unknown command: \"$TCNAME\""
}

################################################################################
# fileutil test function
################################################################################
function do_cat()
{

	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
	echo "testing file for cat" >$TCTMP/cat.txt
	echo "line number 2 abcdefg" >>$TCTMP/cat.txt
	echo "line number 3 hijklmn" >>$TCTMP/cat.txt
	
	cat $TCTMP/cat.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	cat $TCTMP/cat.txt | grep hijklmn >&/dev/null
	tc_pass_or_fail $?  "$summary3" || return

	if ! tc_is_busybox cat ; then
		tc_register "cat -n"
		let TST_TOTAL+=1

		cat -n $TCTMP/cat.txt >/dev/null 2>$stderr
		tc_fail_if_bad $?  "$summary2" || return

		cat -n $TCTMP/cat.txt | grep -v 4 >&/dev/null
		tc_pass_or_fail $?  "$summary3" || return 

		echo "" >>$TCTMP/cat.txt
		echo "" >>$TCTMP/cat.txt
		echo "" >>$TCTMP/cat.txt
		echo "" >>$TCTMP/cat.txt
		
		tc_register "cat -s"
		let TST_TOTAL+=1

		# Check if supporting utilities are available
		tc_exec_or_break  wc || return 
	
		cat -s $TCTMP/cat.txt > $TCTMP/cats.tst 2>$stderr
		tc_fail_if_bad $?  "$summary2" || return 

		wc -l $TCTMP/cats.tst | grep  4 >&/dev/null
		tc_pass_or_fail $?  "$summary3" || return 

	fi
}

function do_comm()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
	echo "1" >$TCTMP/comm1.txt
	echo "2" >>$TCTMP/comm1.txt
	echo "54321" >>$TCTMP/comm1.txt
	
	echo "1" >$TCTMP/comm2.txt
	echo "3" >>$TCTMP/comm2.txt
	echo "4" >>$TCTMP/comm2.txt
	echo "54321" >>$TCTMP/comm2.txt
	
	comm $TCTMP/comm1.txt $TCTMP/comm2.txt > /dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return 

	comm $TCTMP/comm1.txt $TCTMP/comm2.txt | grep 54321 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return 

	tc_register "comm -1"
        let TST_TOTAL+=1

	comm -1 $TCTMP/comm1.txt $TCTMP/comm2.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return 

	comm -1 $TCTMP/comm1.txt $TCTMP/comm2.txt | grep -v 2 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return 

	tc_register "comm -3"
        let TST_TOTAL+=1

	comm -3 $TCTMP/comm1.txt $TCTMP/comm2.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return 

	comm -1 $TCTMP/comm1.txt $TCTMP/comm2.txt | grep -v 54321 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_expand()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep cat || return
	
	echo "1		a	" >$TCTMP/expand.txt
	echo "3		b	" >>$TCTMP/expand.txt
	echo "4		c	" >>$TCTMP/expand.txt
	echo "54321	d	" >>$TCTMP/expand.txt

	if tc_is_busybox expand ; then
		expand $TCTMP/expand.txt > /dev/null 2>>$stderr
		tc_pass_or_fail $?  "$summary2" || return
	else
		expand $TCTMP/expand.txt > /dev/null 2>>$stderr
		tc_fail_if_bad $?  "$summary2" || return

		expand $TCTMP/expand.txt | cat -t | grep -v "\^I" >& /dev/null
		tc_pass_or_fail $?  "$summary3" || return

		tc_register "expand -i"
		let TST_TOTAL+=1

		expand -i $TCTMP/expand.txt > /dev/null 2>$stderr
		tc_fail_if_bad $?  "$summary2" || return

		expand -i $TCTMP/expand.txt | cat -t | grep "\^I" >& /dev/null
		tc_pass_or_fail $?  "$summary3" || return
	fi
}

function do_head()
{
	# Check if supporting utilities are available
	tc_exec_or_break grep echo || return

        echo "1 xyz123" > $TCTMP/head1.txt
	echo "2" >> $TCTMP/head1.txt
	echo "3" >> $TCTMP/head1.txt
	echo "4" >> $TCTMP/head1.txt
	echo "5" >> $TCTMP/head1.txt
	
        echo "1 xyz123" > $TCTMP/head.txt
	echo "2" >> $TCTMP/head.txt
	echo "3" >> $TCTMP/head.txt
	echo "4" >> $TCTMP/head.txt
	echo "5" >> $TCTMP/head.txt
	echo "6" >> $TCTMP/head.txt
	echo "7" >> $TCTMP/head.txt
	echo "8" >> $TCTMP/head.txt
	echo "9" >> $TCTMP/head.txt
	echo "10" >> $TCTMP/head.txt

	head $TCTMP/head.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	head $TCTMP/head.txt | grep 10 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "head -with 2 files."
        let TST_TOTAL+=1

	head $TCTMP/head.txt $TCTMP/head1.txt >/dev/null 2> $stderr
	tc_fail_if_bad $?  "$summary2" || return
	
	head $TCTMP/head.txt $TCTMP/head1.txt | grep -c xyz123 | grep 2 > /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "head -n"
        let TST_TOTAL+=1

	head -n 7 $TCTMP/head.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	head -n 7 $TCTMP/head.txt | grep -v 10 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_nl()
{
	# Check if supporting utilities are available
	tc_exec_or_break echo grep || return

        echo "1" > $TCTMP/nl.txt
	echo "2" >> $TCTMP/nl.txt
	echo "3" >> $TCTMP/nl.txt
	echo "4" >> $TCTMP/nl.txt
	echo "5" >> $TCTMP/nl.txt
	echo "6" >> $TCTMP/nl.txt
	echo "7" >> $TCTMP/nl.txt
	echo "8" >> $TCTMP/nl.txt
	echo "9" >> $TCTMP/nl.txt
	echo "ten" >> $TCTMP/nl.txt

	nl $TCTMP/nl.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	nl $TCTMP/nl.txt | grep 10 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "nl -s" 
        let TST_TOTAL+=1
	
	nl -s abcde $TCTMP/nl.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	nl -s abcde $TCTMP/nl.txt | grep abcde >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_pr()
{
	# Check if supporting utilities are available
	tc_exec_or_break echo grep || return

        echo "1" > $TCTMP/pr.txt
	echo "2" >> $TCTMP/pr.txt
	echo "3" >> $TCTMP/pr.txt
	echo "4" >> $TCTMP/pr.txt
	echo "5" >> $TCTMP/pr.txt
	echo "6" >> $TCTMP/pr.txt
	echo "7" >> $TCTMP/pr.txt
	echo "8" >> $TCTMP/pr.txt
	echo "9" >> $TCTMP/pr.txt
	echo "ten" >> $TCTMP/pr.txt

	cat $TCTMP/pr.txt > $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	cat $TCTMP/pr.txt >> $TCTMP/pr1.txt
	
	pr $TCTMP/pr1.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	pr $TCTMP/pr1.txt | grep [Pp]age >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "pr -h" 
        let TST_TOTAL+=1
	
	pr -h MyTesting $TCTMP/pr1.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	pr -h MyTesting $TCTMP/pr1.txt | grep MyTesting >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "pr -t" 
        let TST_TOTAL+=1
	
	pr -t $TCTMP/pr1.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	pr -t $TCTMP/pr1.txt | grep -v [Pp]age >& /dev/null
	tc_pass_or_fail $?  "$summary3"
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

	sort $TCTMP/sort.txt > $TCTMP/sorted.tst 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

        echo "1" > $TCTMP/sort1.txt
	echo "2" >> $TCTMP/sort1.txt
	echo "3" >> $TCTMP/sort1.txt
	echo "a" >> $TCTMP/sort1.txt
	echo "b" >> $TCTMP/sort1.txt
	echo "c" >> $TCTMP/sort1.txt

	diff $TCTMP/sorted.tst $TCTMP/sort1.txt >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "sort -r" 
        let TST_TOTAL+=1
	
	sort -r $TCTMP/sort.txt > $TCTMP/sort_r.tst 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	echo "c" > $TCTMP/sorted_r.txt
	echo "b" >> $TCTMP/sorted_r.txt
	echo "a" >> $TCTMP/sorted_r.txt
	echo "3" >> $TCTMP/sorted_r.txt
	echo "2" >> $TCTMP/sorted_r.txt
        echo "1" >> $TCTMP/sorted_r.txt
	
	diff $TCTMP/sort_r.tst $TCTMP/sorted_r.txt >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "sort -c" 
        let TST_TOTAL+=1
	
	sort -c $TCTMP/sorted.tst > $TCTMP/sort_r.tst 2>>$stderr
	tc_pass_or_fail $?  "$summary3"
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
	
	tac $TClTMP/tac.txt >$TCTMP/tac.tst l2>>$stderr
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
function do_tsort()
{
	# Check if supporting utilities are available
	tc_exec_or_break  diff echo || return
	
        echo "1" > $TCTMP/tsort.txt
	echo "2" >> $TCTMP/tsort.txt
	echo "a" >> $TCTMP/tsort.txt
	echo "b" >> $TCTMP/tsort.txt
	
	tsort $TCTMP/tsort.txt > $TCTMP/tsort1.tst 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

        echo "1" > $TCTMP/tsort.tst
	echo "a" >> $TCTMP/tsort.tst
	echo "2" >> $TCTMP/tsort.tst
	echo "b" >> $TCTMP/tsort.tst
	
	diff $TCTMP/tsort.tst $TCTMP/tsort1.tst >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}
function do_wc()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1" > $TCTMP/wc.txt
	echo "2" >> $TCTMP/wc.txt
	echo "3" >> $TCTMP/wc.txt
	echo "a dog" >> $TCTMP/wc.txt
	echo "b cat" >> $TCTMP/wc.txt
	echo "c duck" >> $TCTMP/wc.txt
	
	wc $TCTMP/wc.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	wc $TCTMP/wc.txt | grep 9 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "wc -l"
        let TST_TOTAL+=1

	wc -l $TCTMP/wc.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	wc -l $TCTMP/wc.txt | grep 6 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}
function do_csplit()
{
	TCNAME="csplit with an integer"

	# Check if supporting utilities are available
	tc_exec_or_break  echo || return
	
        echo "1" > $TCTMP/csplit.txt
	echo "2" >> $TCTMP/csplit.txt
	echo "3" >> $TCTMP/csplit.txt
	echo "a dog" >> $TCTMP/csplit.txt
	echo "b cat" >> $TCTMP/csplit.txt
	echo "c duck" >> $TCTMP/csplit.txt
	
	cd $TCTMP >& /dev/null

	csplit  $TCTMP/csplit.txt 2 >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	if [ -s $TCTMP/xx00 -a -s $TCTMP/xx01 ]; then
		tc_pass_or_fail 0  "$summary3" || return
	else
		tc_pass_or_fail 1  "$summary3" || return
	fi

	tc_register "csplit -f /REGEXP/"
        let TST_TOTAL+=1

	csplit -f csplityy $TCTMP/csplit.txt /cat/ >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	[ -s $TCTMP/csplityy00 -a -s $TCTMP/csplityy01 ]
	tc_pass_or_fail $?  "$summary3"
}
function do_fmt()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
	echo "1.  This is a test file for testing the fmt command." \
		> $TCTMP/fmt.txt
	echo "2.  If a test problem exists, then debug debug until you drop." \
		>> $TCTMP/fmt.txt
	
	fmt $TCTMP/fmt.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	fmt $TCTMP/fmt.txt | grep -c test | grep 1 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "fmt -w"
        let TST_TOTAL+=1

	fmt -w 50 $TCTMP/fmt.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	fmt -w 50 $TCTMP/fmt.txt | grep -c test | grep 2 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}
function do_join()
{
	# Check if supporting utilities are available
	tc_exec_or_break  grep || return
	
        echo "1 duck" > $TCTMP/join.txt
	echo "2" >> $TCTMP/join.txt
	echo "3 cat" >> $TCTMP/join.txt

	echo "1 dog" > $TCTMP/join2.txt
	echo "2 cat" >> $TCTMP/join2.txt
	echo "3 duck" >> $TCTMP/join2.txt
	echo "4 duck" >> $TCTMP/join2.txt
	
	join $TCTMP/join.txt $TCTMP/join2.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	join $TCTMP/join.txt $TCTMP/join2.txt | grep -v 4 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_od()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
	echo "1" > $TCTMP/od.txt
	echo "2" >> $TCTMP/od.txt
	echo "3" >> $TCTMP/od.txt
	
	od $TCTMP/od.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	od $TCTMP/od.txt | grep 0000006 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "od -tc"
        let TST_TOTAL+=1

	od -tc $TCTMP/od.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	od -tc $TCTMP/od.txt | grep \n >& /dev/null
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
	
	split $TCTMP/split.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	if [ -s $TCTMP/xaa ]; then
		tc_pass_or_fail 0  "$summary3"
	else
		tc_pass_or_fail 1  "$summary3" || return
	fi

	tc_register "split -l"
        let TST_TOTAL+=1

	split -l 2 $TCTMP/split.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	[ -s xaa -a -s xab -a -s xac ]
	tc_pass_or_fail $?  "$summary3"
}

function do_tail()
{
	# Check if supporting utilities are available
	tc_exec_or_break grep echo || return

        echo "1" > $TCTMP/tail1.txt
	echo "2" >> $TCTMP/tail1.txt
	echo "3" >> $TCTMP/tail1.txt
	echo "4" >> $TCTMP/tail1.txt
	echo "5 xyz123" >> $TCTMP/tail1.txt
	
        echo "1" > $TCTMP/tail.txt
	echo "2" >> $TCTMP/tail.txt
	echo "3" >> $TCTMP/tail.txt
	echo "4" >> $TCTMP/tail.txt
	echo "5" >> $TCTMP/tail.txt
	echo "6" >> $TCTMP/tail.txt
	echo "7" >> $TCTMP/tail.txt
	echo "8" >> $TCTMP/tail.txt
	echo "9" >> $TCTMP/tail.txt
	echo "10 xyz123" >> $TCTMP/tail.txt

	tail $TCTMP/tail.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	tail $TCTMP/tail.txt | grep 10 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "tail -with 2 files"
        let TST_TOTAL+=1

	tail $TCTMP/tail.txt $TCTMP/tail1.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return
	
	tail $TCTMP/tail1.txt $TCTMP/tail.txt | grep -c xyz123 | grep 2 > /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "tail -n"
        let TST_TOTAL+=1

	tail -n 7 $TCTMP/tail.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	tail -n 7 $TCTMP/tail.txt | grep -v 1 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_unexpand()
{
	# Check if supporting utilities are available
	tc_exec_or_break grep cat echo || return
	
        echo "                16" > $TCTMP/unexpand.txt
	if tc_is_busybox unexpand ; then	
		unexpand $TCTMP/unexpand.txt >$TCTMP/unexpand.tst 2>>$stderr
		tc_pass_or_fail $?  "$summary2"
	else
		unexpand $TCTMP/unexpand.txt >$TCTMP/unexpand.tst 2>>$stderr
		tc_fail_if_bad $?  "$summary2" || return

		cat -t $TCTMP/unexpand.tst | grep "\^I" >& /dev/null
		tc_pass_or_fail $?  "$summary3"
	fi
}
function do_cksum()
{
	# Check if supporting utilities are available
	tc_exec_or_break  awk echo || return
	
        echo "1" > $TCTMP/cksum.txt
	echo "2" >> $TCTMP/cksum.txt
	echo "a" >> $TCTMP/cksum.txt
	echo "b" >> $TCTMP/cksum.txt

	local mychsum=0
	
	cksum $TCTMP/cksum.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return
	
	mychsum=`cksum $TCTMP/cksum.txt | awk '{print $1}' 2> /dev/null`
	if [ $mychsum -ne 1383642305 ]; then
		tc_pass_or_fail 1  "$summary3"

	else
		tc_pass_or_fail 0  "$summary3" 
	fi
}

function do_cut()
{
	TCNAME="cut -fd"

	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1:two:three" > $TCTMP/cut.txt
	echo "2:3:four" >> $TCTMP/cut.txt
	echo "3 is my test flag zzyyww" >> $TCTMP/cut.txt
	
	cut -f2 -d: $TCTMP/cut.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	cut -f2 -d: $TCTMP/cut.txt | grep two >& /dev/null
	tc_fail_if_bad $?  "$summary2" || return

	cut -f2 -d: $TCTMP/cut.txt | grep zzyyww >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_fold()
{
	TCNAME="fold -w"

	# Check if supporting utilities are available
	tc_exec_or_break  echo || return
	
        echo "one is that.              one is this." > $TCTMP/fold.txt
        echo "two is this.              two is that." >> $TCTMP/fold.txt
	
	fold -w 20 $TCTMP/fold.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	fold -w 20 $TCTMP/fold.txt | grep -c one | grep 2 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_md5sum()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1" > $TCTMP/md5sum.txt
	echo "2" >> $TCTMP/md5sum.txt
	echo "a" >> $TCTMP/md5sum.txt
	echo "b" >> $TCTMP/md5sum.txt
	
	md5sum  md5sum.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	md5sum  md5sum.txt | grep d4a59fc154c4bba3dd6aa3f5a81de972 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "md5sum -c"
        let TST_TOTAL+=1

	md5sum  md5sum.txt >$TCTMP/md5sum.tst 2>$stderr

	md5sum -c  md5sum.tst > /dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	md5sum -c  md5sum.tst | grep OK >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_paste()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1 This is a test for the paste command for fun for fun for fun." \
	> $TCTMP/paste.txt
	echo "2 That is a test for the paste command for fun for fun for fun." \
	>> $TCTMP/paste.txt
        echo "3 This is a test for the paste command for fun for fun for fun." \
	> $TCTMP/paste.tst
	
	paste $TCTMP/paste.txt $TCTMP/paste.tst >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	paste $TCTMP/paste.txt $TCTMP/paste.tst | grep -c This | grep 1 \
	>& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "paste -s"
        let TST_TOTAL+=1

	paste -s $TCTMP/paste.txt $TCTMP/paste.tst >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	paste -s $TCTMP/paste.txt $TCTMP/paste.tst | grep -c This | grep 2 \
	>& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_sha1sum()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1" > $TCTMP/sha1sum.txt
	echo "2" >> $TCTMP/sha1sum.txt
	echo "a" >> $TCTMP/sha1sum.txt
	echo "b" >> $TCTMP/sha1sum.txt
	
	sha1sum  sha1sum.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	sha1sum  sha1sum.txt | grep fda99526e6a2267c6941d424866aaa29d6104b00 \
	>& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "sha1sum -c"
        let TST_TOTAL+=1

	sha1sum  sha1sum.txt >$TCTMP/sha1sum.tst 2>$stderr

	sha1sum -c  sha1sum.tst > /dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	sha1sum -c  sha1sum.tst | grep OK >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_sum()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1" > $TCTMP/sum.txt
	echo "2" >> $TCTMP/sum.txt
	echo "a" >> $TCTMP/sum.txt
	echo "b" >> $TCTMP/sum.txt
	
	sum  sum.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	sum  sum.txt | grep 23116 >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_tr()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo grep || return
	
        echo "1 his" > $TCTMP/tr.txt
	echo "2 testing" >> $TCTMP/tr.txt
	echo "3 file" >> $TCTMP/tr.txt
	
	tr his her < $TCTMP/tr.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	tr his her < $TCTMP/tr.txt | grep her >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "tr -d"
        let TST_TOTAL+=1

	tr -d his < $TCTMP/tr.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	tr -d his < $TCTMP/tr.txt | grep -v his >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register 'tr -[:..:]'
        let TST_TOTAL+=1

	tr [:lower:] [:upper:] < $TCTMP/tr.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	tr [:lower:] [:upper:] < $TCTMP/tr.txt | grep HIS >& /dev/null
	tc_pass_or_fail $?  "$summary3"
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
	
	uniq $TCTMP/uniq.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	uniq $TCTMP/uniq.txt | grep -c cat | grep 1  >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "uniq -u"
        let TST_TOTAL+=1

	uniq -u $TCTMP/uniq.txt >/dev/null 2>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	uniq -u $TCTMP/uniq.txt | grep -v cat  >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "uniq -c"
        let TST_TOTAL+=1

	uniq -c $TCTMP/uniq.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	uniq -c $TCTMP/uniq.txt | grep 3  >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_ptx()
{
	# Check if supporting utilities are available
	tc_exec_or_break  echo || return
	
        echo "1" > $TCTMP/ptx.txt
	echo "2" >> $TCTMP/ptx.txt
	echo "a" >> $TCTMP/ptx.txt
	echo "b" >> $TCTMP/ptx.txt
	
	ptx $TCTMP/ptx.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	ptx $TCTMP/ptx.txt | grep -c a | grep 2 >& /dev/null
	tc_pass_or_fail $?  "$summary3" || return

	tc_register "ptx -O"
        let TST_TOTAL+=1

	ptx -O $TCTMP/ptx.txt >/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$summary2" || return

	ptx -O $TCTMP/ptx.txt | grep "\"b\"" >& /dev/null
	tc_pass_or_fail $?  "$summary3"
}

function do_cp()
{
        tc_exec_or_break "mkdir" "echo" "ln" || return
        mkdir $TCTMP/dir1
        mkdir $TCTMP/dir2
        mkdir $TCTMP/dir3
        mkdir $TCTMP/dir4
        echo "some text" > $TCTMP/dir1/myfile
        echo "some other text" > $TCTMP/dir2/myotherfile
        ln -s $TCTMP/dir1/myfile $TCTMP/dir2/mysymlink
        ln    $TCTMP/dir1/myfile $TCTMP/dir3/myhardlink
        cp $TCTMP/dir1/* $TCTMP/dir4
        cp -d $TCTMP/dir2/* $TCTMP/dir4 # no deref symlinks
        cp $TCTMP/dir3/* $TCTMP/dir4
        tc_pass_or_fail $? "unexpected output"
}

function do_mkdir() 
{
        tc_exec_or_break ls grep touch || return
        mkdir $TCTMP/do_mkdir >$stdout 2>$stderr
        touch $TCTMP/do_mkdir/touched
        ls -l $TCTMP/do_mkdir | grep touched >/dev/null
        tc_pass_or_fail $? "`ls -l $TCTMP/do_mkdir`"
}

function do_chgrp() {
        tc_root_or_break || return
        tc_exec_or_break rm touch ls grep || return
        tc_add_group_or_break || return
        rm $TCTMP/xxx 2>/dev/null
        touch $TCTMP/xxx       # should have group "root"
        chgrp $TC_TEMP_GROUP $TCTMP/xxx >$stdout 2>$stderr
        ls -l $TCTMP/xxx | grep "$TC_TEMP_GROUP" >/dev/null 2>>$stderr
        tc_pass_or_fail $? "unexpected output"
}

function do_chmod() {
        tc_exec_or_break "rm" "touch" "ls" "cut" || return
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
        rm $TCTMP/xxx 2>/dev/null
        touch $TCTMP/xxx
        local failed=""
        for x in 1 2 3 4 5 6 7 8 9 a; do        # count must match the above!
                eval chmod \$cmd$x $TCTMP/xxx >$stdout 2>$stderr
                eval act$x=`ls -l $TCTMP/xxx | cut -d" " -f1`

                if ! eval [ \$exp$x = \$act$x ] ; then
                        eval failed="\" \$cmd$x failed with \$act$x expected \$exp$x\""
                        break
                fi
        done
        [ "$failed" = "" ]
        tc_pass_or_fail $? "$failed"
}

function do_chown() {
        tc_root_or_break || return
        tc_exec_or_break "grep" "ls" || return
        tc_add_user_or_break &>/dev/null || return
        touch $TCTMP/chowntest
        chown $TC_TEMP_USER $TCTMP/chowntest >$stdout 2>$stderr
        local result="`ls -l $TCTMP/chowntest`"
        echo $result$ | grep $TC_TEMP_USER >/dev/null
        tc_pass_or_fail $? "result: $result"
        tc_del_user_or_break &>/dev/null
}

function do_dd() {
        tc_exec_or_break "grep" "ls" || return
        local actual1 actual2 failed expected1 expected2
        expected1="8+0 records out"
        expected2="8388608"
        actual1=`dd if=/dev/zero of=$TCTMP/image bs=1024k count=8 2>&1 \
                | grep "$expected1" 2>$stderr`
        actual2=`ls -l $TCTMP/image | grep "$expected2"`
        failed="expected \"$expected1\", got \"$actual1\"
                        expected \"$expected2\", got \"$actual2\""
        [ "$actual1" ] && [ "$actual2" ]
        tc_pass_or_fail $? "$failed"
}

function do_df() {
	tc_get_os_arch
	tc_exec_or_break "grep" || return
	tc_exist_or_break "/proc/mounts" || return
	df >$stdout 2>$stderr
	if [ $TC_OS_ARCH = ppcnf ]; then
		NFS_ROOT=`sed 's/ /\n/g' /proc/cmdline | grep "nfsroot" | cut -d"=" -f2`
		grep $NFS_ROOT $stdout >/dev/null 2>$stderr
	else
		grep "\/dev" $stdout >/dev/null 2>$stderr
	fi
	tc_pass_or_fail $? "unexpected output"
}

function do_du() {
        tc_exec_or_break "echo" || return
        local result1 result2 size1 size2
        declare -i size1 size2
        result1=`du -s $TCTMP 2>>$stderr`
        echo "Hello CSDL" > $TCTMP/du_test
        result2=`du -s $TCTMP 2>>$stderr`
        read size1 junk <<-EOF
                `echo $result1`
	EOF
        read size2 junk <<-EOF
                `echo $result2`
	EOF
        [ $size2 -gt $size1 ]
        tc_pass_or_fail $? "expected \"$size1\" to be greater than \"$size1\""
}

function do_kill()
{
        tc_exec_or_break cat chmod ps grep || return

        tc_info "ugly \"Terminated\" message is normal."

        local script=$TCTMP/script$$
	cat > $script <<-EOF
		#!$SHELL
		# script to loop until killed
		echo \$\$ > $TCTMP/scriptpid
		while : ; do
			sleep 1
		done
	EOF
        chmod +x $script
        eval $script &  # eval so full name shows in terminated message
	tc_wait_for_file $TCTMP/scriptpid 10 size
	tc_fail_if_bad $? "Could not get PID for $TCTMP/script$$" || return

	killme=$(<$TCTMP/scriptpid)
        kill $killme >$stdout 2>$stderr
	tc_pass_or_fail $? "Unexpected response from kill $killme" || return
}

function do_ln()
{
        tc_exec_or_break touch echo grep || return

        local result expected
        local file=$TCTMP/ln_test_file1
        local symlink=$TCTMP/ln_test_sym
        local hrdlink=$TCTMP/ln_test_hrd
        touch $file

        TCNAME="ln01 - symbolic link"
        ln -s $file $symlink 2>$stderr
        result="`ls -l $symlink 2>$stderr`"
        echo $result | grep "^l.*ln_test_sym.*ln_test_file1" >/dev/null
        tc_pass_or_fail $? "expected to see symlink from $file to $symlink in \"$result\""

        tc_register "ln02 - hard link"
        let TST_TOTAL+=1
        ln $file $hrdlink 2>$stderr
        result="`ls -l $hrdlink 2>$stderr`"
        echo $result | grep "^-.* 2 .*ln_test_hrd$" >/dev/null
        tc_pass_or_fail $? \
                "expected to see link count of 2 for ln_test_hrd in \"$result\""
}

function do_ls()
{
        tc_exec_or_break touch || return

        touch $TCTMP/ls_test_
        local result="`ls $TCTMP/ls_test_ 2>$stderr`"
        [ "$result" ]
        tc_pass_or_fail $? "ls did not return file named $TCTMP/ls_test_"
}

function do_rm()
{
        tc_exec_or_break ls grep || return

        touch $TCTMP/rm_me
        rm $TCTMP/rm_me 2>$stderr
        local result="`ls $TCTMP/rm_me 2>&1`"
        echo $result | grep "No such file or directory" >/dev/null
        tc_pass_or_fail $? \
                "Expected file \"$TCTMP/rm_me\" to be removed, but it wasn't"
}

function do_rmdir()
{
        tc_exec_or_break mkdir ls grep || return

        mkdir -p $TCTMP/rm_me
        rmdir $TCTMP/rm_me 2>$stderr
        local result="`ls $TCTMP/rm_me 2>&1`"
        echo $result | grep "No such file or directory" >/dev/null
        tc_pass_or_fail $? \
                "Expected dir \"$TCTMP/rm_me\" to be removed, but it wasn't"
}

function do_touch()
{
        tc_exec_or_break rm grep || return
        rm -fd $TCTMP/touchtest &>/dev/null
        touch $TCTMP/touchtest 2>$stderr
        local result="`ls -l $TCTMP/touchtest`"
        echo $result | grep "$TCTMP/touchtest" >/dev/null
        tc_pass_or_fail $? "Expected \"$TCTMP/touchtest\", got \"$result\""
}


function do_mv()
{
        tc_exec_or_break cat echo || return

        local contents="Hello Sailor"
        echo "$contents" > $TCTMP/original
        mv $TCTMP/original $TCTMP/newname 2>$stderr
        [ "$contents" = "$(<$TCTMP/newname)" ]
        tc_pass_or_fail $? "expected $TCTMP/newname to contain \"$contents\""
}

function do_uptime() {
        tc_exec_or_break "grep" || return
        uptime | grep "load average:" >$stdout 2>$stderr
        tc_pass_or_fail $? "unexpected results"
}

################
function do_mknod()
{
	unimplemented
}

function do_chcon()
{
	unimplemented
}

function do_dir()
{
	unimplemented
}

function do_dircolors()
{
	unimplemented
}

function do_install()
{
	unimplemented
}

function do_link()
{
	unimplemented
}

function do_mkfifo()
{
	unimplemented
}

function do_readlink()
{
	unimplemented
}

function do_runcon()
{
	unimplemented
}

function do_shred()
{
	unimplemented
}

function do_stat()
{
	unimplemented
}

function do_sync()
{
	unimplemented
}

function do_tac()
{
	unimplemented
}

function do_unlink()
{
	unimplemented
}

function do_vdir()
{
	unimplemented
}

################################################################################
# main
################################################################################

tc_setup

#
# run tests against all commands in sh-utils package.
#
for name in $names ; do
	tc_register $name
	case $name in
		[)		do_LBR		; ;;
		basename)	do_basename	; ;;
		chroot)		do_chroot	; ;;
		date)		do_date		; ;;
		dirname)	do_dirname	; ;;
		echo)		do_echo		; ;;
		env)		do_env		; ;;
		expr)		do_expr		; ;;
		factor)		do_factor	; ;;
		false)		do_false	; ;;
		groups)		do_groups	; ;;
		id)		do_id		; ;;
		logname)	do_logname	; ;;
		nice)		do_nice		; ;;
		nohup)		do_nohup	; ;;
		pathchk)	do_pathchk	; ;;
		pinky)		do_pinky ipv4	; ;;
		printenv)	do_printenv	; ;;
		printf)		do_printf	; ;;
		pwd)		do_pwd		; ;;
		seq)		do_seq		; ;;
		sleep)		do_sleep	; ;;
		stty)		do_stty		; ;;
		su)		do_su		; ;;
		tee)		do_tee		; ;;
		test)		do_test		; ;;
		true)		do_true		; ;;
		tty)		do_tty		; ;;
		uname)		do_uname	; ;;
		users)		do_users	; ;;
		who)		do_who ipv4	; ;;
		whoami)		do_whoami	; ;;
		yes)		do_yes		; ;;
		cat)		do_cat		; ;;
		comm)		do_comm		; ;;
		expand)		do_expand	; ;;
		head)		do_head		; ;;
		nl)		do_nl		; ;;
		pr)		do_pr		; ;;
		sort)		do_sort		; ;;
		tsort)		do_tsort	; ;;
		wc)		do_wc		; ;;
		csplit)		do_csplit	; ;;
		fmt)		do_fmt		; ;;
		join)		do_join		; ;;
		od)		do_od		; ;;
		split)		do_split	; ;;
		tail)		do_tail		; ;;
		unexpand)	do_unexpand	; ;;
		cksum)		do_cksum	; ;;
		cut)		do_cut		; ;;
		fold)		do_fold		; ;;
		md5sum)		do_md5sum	; ;;
		paste)		do_paste	; ;;
		sha1sum)	do_sha1sum	; ;;
		sum)		do_sum		; ;;
		tr)		do_tr		; ;;
		uniq)		do_uniq		; ;;
		ptx)		do_ptx		; ;;
		cp)		do_cp		; ;;
		mkdir)		do_mkdir	; ;;
		chgrp)		do_chgrp	; ;; 
		chmod)		do_chmod	; ;; 
		chown)		do_chown	; ;; 
		dd)		do_dd		; ;; 
		df)		do_df		; ;; 
		du)		do_du		; ;; 
		kill)		do_kill		; ;; 
		ln)		do_ln		; ;; 
		ls)		do_ls		; ;; 
		rm)		do_rm		; ;; 
		rmdir)		do_rmdir	; ;; 
		touch)		do_touch	; ;; 
		mknod)		do_mknod	; ;; 
		mv)		do_mv		; ;; 
		uptime)		do_uptime	; ;; 
		*)		do_unknown	; ;;
	esac
done

############## Checking for IPv6 ################### 

tc_ipv6_info && [ "$TC_IPV6_ADDRS" ] && {
        [ "$TC_IPV6_host_ADDRS" ] && host="$TC_IPV6_host_ADDRS"
        [ "$TC_IPV6_global_ADDRS" ] && host="$TC_IPV6_global_ADDRS"
        [ "$TC_IPV6_link_ADDRS" ] && host="$TC_IPV6_link_ADDRS%$TC_IPV6_link_IFACES"
	host=$(tc_ipv6_normalize $host)
        tc_info "BEGIN IPv6 Tests using host $host"
        ((TST_TOTAL+=2))
        tc_register "who ipv6"
        do_who ipv6
        tc_register "pinky ipv6"
        do_pinky ipv6
}

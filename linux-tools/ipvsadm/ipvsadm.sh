#!/bin/bash
###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##	1.Redistributions of source code must retain the above copyright notice,          ##
##        this list of conditions and the following disclaimer.                           ##
##	2.Redistributions in binary form must reproduce the above copyright notice, this  ##
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
## File :	ipvsadm.sh
##
## Description:	ipvsadm utility for Virtual Server table manipulation
##
## Authors:	Manikandan .C , Suzuki K P <suzukikp@in.ibm.com>
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
## Description:	ipvsadm utility for Virtual Server table manipulation
source $LTPBIN/tc_utils.source
TESTDIR=${PWD%%/fivextra/*}/fivextra/ipvsadm/

NL=$'\r'

# The table may have diff. rule ordering
function compare_tables()
{
	local exp=$TCTMP/expected
	local actual=$TCTMP/actual

	sort $1 > $exp
	sort $2 > $actual

	diff -bB $exp $actual >$stderr
}

	
# Tests clearing the virtual server table
function test_clear_virtual_table()
{
	tc_register "Clear Virtual Server Table"

	# Create empty output file
	echo -n "" > $LOGDIR/result.exp

	ipvsadm -C >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to clear the tables" || return
	
	# Dump virtual servers table, which should be empty
	ipvsadm -Sn >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to dump the tables" || return

	compare_tables $LOGDIR/result.exp $stdout
#        diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to clear virtual servers table"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

# Tests restoring virtual server table from a file and saving the table to a file
test_restore_and_dump_vtable()
{
	tc_register "Restore and dump virtual server table"
	# Clear the table
	ipvsadm -C >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to clear the table" || return
	
	# Create sample table
	cat <<EOF > $LOGDIR/result.exp
-A -t 192.168.1.1:80 -s wrr -p 600
-a -t 192.168.1.1:80 -r 10.1.1.2:80 -g -w 2
-a -t 192.168.1.1:80 -r 10.1.1.3:80 -g -w 3
EOF
	
	# Restore table from the file (stdin in this case) and compare
	ipvsadm -R  <<EOF >$stdout 2>$stderr
-A -t 192.168.1.1:80 -s wrr -p 600
-a -t 192.168.1.1:80 -r 10.1.1.3:80 -g -w 3
-a -t 192.168.1.1:80 -r 10.1.1.2:80 -g -w 2
EOF
	tc_fail_if_bad $? "Failed to restore tables from stdin" || return

    ipvsadm -Sn >$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to dump table" || return

	compare_tables $LOGDIR/result.exp $stdout
	tc_pass_or_fail $? "Failed to restore and dump virtual server table"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
	
}

# Tests adding virtual server
test_add_virtual_server()
{
	tc_register "Add virtual servers"
	ipvsadm -C >$stdout 2>$stderr
	
	 # Add tcp virtual HTTP(80) service
	 # with Round Robin(-s rr) and 600 s persistence
	ipvsadm -A -t 192.168.1.1:80 -s rr -p 600 >$stdout 2>$stderr
	
	 # Add udp virtual port 69 service 
	 # with least connection scheduler and netmask option
	ipvsadm -A -u 192.168.1.2:69 -M 255.255.0.0 -s lc >$stdout 2>$stderr
	
	 # create fireall mark service and destination hashing scheduler
	ipvsadm -A -f 2 -s dh >$stdout 2>$stderr

	cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s lc
-A -t 192.168.1.1:80 -s rr -p 600
-A -f 2 -s dh
EOF
	# dump the ipvs table
	ipvsadm -Sn >$stdout 2>$stderr
	compare_tables $LOGDIR/result.exp $stdout
#	diff -b $LOGDIR/result.exp $stdout &>/dev/null
	tc_pass_or_fail $? "Failed to add virtual servers"\
	"========= Expected Output ========="\
	"$NL$(< $LOGDIR/result.exp)"
}

# Tests adding real server
test_add_real_server()
{
	tc_register "Add real servers"
	ipvsadm -C  >$stdout 2>$stderr
	
	# Create a few virtual servers to which the real servers will be added
        ipvsadm -R <<EOF >$stdout 2>$stderr
-A -t 192.168.1.1:80 -s rr -p 600 
-A -u 192.168.1.2:69 -s lc 
-A -f 2 -s dh
EOF

	tc_fail_if_bad $? "Failed to add real servers" || return

	cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s lc
-a -u 192.168.1.2:69 -r 10.1.2.4:69 -m -w 1
-a -u 192.168.1.2:69 -r 10.1.2.3:69 -i -w 1
-a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2
-A -t 192.168.1.1:80 -s rr -p 600
-a -t 192.168.1.1:80 -r 10.1.1.4:80 -i -w 6
-a -t 192.168.1.1:80 -r 10.1.1.3:80 -g -w 3
-a -t 192.168.1.1:80 -r 10.1.1.2:80 -m -w 1
-A -f 2 -s dh
-a -f 2 -r 192.168.3.4:0 -g -w 1
-a -f 2 -r 192.168.3.3:0 -m -w 3
-a -f 2 -r 192.168.3.2:0 -i -w 3
EOF
	
	# Add 3 real servers with different routing mechanism( -m, -i & -g(default)) with some weight.
	ipvsadm -a -t 192.168.1.1:80 -r 10.1.1.2:80 -m >$stdout 2>>$stderr &&
	ipvsadm -a -t 192.168.1.1:80 -r 10.1.1.3:80 -w 3 >$stdout 2>>$stderr &&
	ipvsadm -a -t 192.168.1.1:80 -r 10.1.1.4:80 -i -w 6 >$stdout 2>>$stderr

	tc_fail_if_bad $? "Failed to add virtual servers for 192.168.1.1:80" || return
	
	# Add a udp virtual TFTP(69) service with "Least connection" scheduling
	ipvsadm -a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2 >$stdout 2>>$stderr &&
	ipvsadm -a -u 192.168.1.2:69 -r 10.1.2.3:69 -i >$stdout 2>>$stderr &&
	ipvsadm -a -u 192.168.1.2:69 -r 10.1.2.4:69 -m >$stdout 2>>$stderr

	tc_fail_if_bad $? "Failed to add virtual servers for 192.168.1.2:69" || return

	# Add a firewall mark with "2" and "destination hashing"(dh) scheduling.
	ipvsadm -a -f 2 -r 192.168.3.2:0 -i -w 3 >$stdout 2>>$stderr &&
	ipvsadm -a -f 2 -r 192.168.3.3:0 -m -w 3 >$stdout 2>>$stderr &&
	ipvsadm -a -f 2 -r 192.168.3.4:0 >$stdout 2>>$stderr 
	
	tc_fail_if_bad $? "Failed to add firewall marker with 2" || return

	# Store the table to verify the results.
	ipvsadm -Sn >$stdout 2>$stderr
	compare_tables $LOGDIR/result.exp $stdout
#	diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to add virtual servers"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

# Test editing virtual server entries
test_edit_virtual_server()
{
        tc_register "Edit virtual servers"
        ipvsadm -C  >$stdout 2>$stderr

        # Create a few virtual server entries, that can be edited
        ipvsadm -R <<EOF >$stdout 2>$stderr
-A -t 192.168.1.1:80 -s rr -p 600
-A -u 192.168.1.2:69 -s lc
-A -f 2 -s dh
EOF

        cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s sed
-A -t 192.168.1.1:80 -s wlc -p 1200
-A -f 2 -s dh
EOF
	
        # Edit and change the scheduler to Shortest Expected Delay
        ipvsadm -E -u 192.168.1.2:69 -s sed  >$stdout 2>$stderr

	# Edit and change persistence to 1200
        ipvsadm -E -t 192.168.1.1:80 -p 1200  >$stdout 2>$stderr

        # Store the table to verify the results.
        ipvsadm -Sn >$stdout 2>$stderr

		compare_tables $LOGDIR/result.exp $stdout
#        diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to add virtual servers"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

# Test Editing Real Servers
test_edit_real_server()
{
        tc_register "Edit real servers"
        ipvsadm -C  >$stdout 2>$stderr

        # Create a few real server entries, that can be edited
        ipvsadm -R <<EOF >$stdout 2>$stderr
-A -u 192.168.1.2:69 -s lc
-a -u 192.168.1.2:69 -r 10.1.2.4:69 -m -w 1
-a -u 192.168.1.2:69 -r 10.1.2.3:69 -i -w 1
-a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2
EOF

        cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s lc
-a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2
-a -u 192.168.1.2:69 -r 10.1.2.3:69 -i -w 1
-a -u 192.168.1.2:69 -r 10.1.2.4:69 -g -w 10
EOF

	# Edit and change packet forwarding to tunneling
	ipvsadm -e -u 192.168.1.2:69 -r 10.1.2.3:69 -i  >$stdout 2>$stderr
        
	# Edit and change weight to 10
	ipvsadm -e -u 192.168.1.2:69 -r 10.1.2.4:69 -w 10  >$stdout 2>$stderr

	# Store the table to verify the results.
	ipvsadm -Sn >$stdout 2>$stderr

	compare_tables $LOGDIR/result.exp $stdout
#     diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to add virtual servers"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

# Test deleting virtual server entriess from the table
test_delete_virtual_server()
{
        tc_register "Delete Virtual servers"
        ipvsadm -C  >$stdout 2>$stderr

        # Create a few virtual server entries, that can be deleted
        ipvsadm -R <<EOF >$stdout 2>$stderr
-A -t 192.168.1.1:80 -s rr -p 600
-A -t 192.168.1.1:23 -s wlc -p 700
-A -u 192.168.1.2:69 -s lc
-A -u 192.168.1.2:40 -s rr
-A -f 2 -s dh
EOF

        cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s lc
-A -t 192.168.1.1:80 -s rr -p 600
-A -f 2 -s dh
EOF

        # Delete 2 virtual servers
        ipvsadm -D -t 192.168.1.1:23 >$stdout 2>$stderr
        ipvsadm -D -u 192.168.1.2:40 >$stdout 2>$stderr

        # Store the table to verify the results.
        ipvsadm -Sn >$stdout 2>$stderr
	compare_tables $LOGDIR/result.exp $stdout
#        diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to add virtual servers"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

test_delete_real_server()
{
        tc_register "Delete Real servers"
        ipvsadm -C  >$stdout 2>$stderr

        # Create a few real server entries, that can be edited
        ipvsadm -R <<EOF >$stdout 2>$stderr
-A -u 192.168.1.2:69 -s lc
-a -u 192.168.1.2:69 -r 10.1.2.4:69 -m -w 1
-a -u 192.168.1.2:69 -r 10.1.2.3:69 -i -w 1
-a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2
EOF

        cat <<EOF > $LOGDIR/result.exp
-A -u 192.168.1.2:69 -s lc
-a -u 192.168.1.2:69 -r 10.1.2.2:69 -g -w 2
EOF

        # Delete 2 real servers
        ipvsadm -d -u 192.168.1.2:69 -r 10.1.2.3:69 >$stdout 2>$stderr &&
        ipvsadm -d -u 192.168.1.2:69 -r 10.1.2.4:69 >$stdout 2>>$stderr

	tc_fail_if_bad $? "Failed to delete real server" || return

        # Store the table to verify the results.
        ipvsadm -Sn >$stdout 2>$stderr

	compare_tables $LOGDIR/result.exp $stdout
#	diff -b $LOGDIR/result.exp $stdout &>/dev/null
        tc_pass_or_fail $? "Failed to delete virtual servers"\
        "========= Expected Output ========="\
        "$NL$(< $LOGDIR/result.exp)"
}

tc_local_cleanup()
{
	ipvsadm -C
	rm -rf $LOGDIR
	[ -f $TCTMP/tables.backup ] && ipvsadm -R < $TCTMP/tables.backup
}

tc_local_setup()
{
	tc_root_or_break || exit

#	modprobe ip_vs 2>$stderr
#	tc_break_if_bad_rc $? "Could not load ip_vs module." || exit 1

	tc_executes diff ipvsadm
	tc_break_if_bad_rc $? "Cannot execute ipvsadm" || exit 1

	ipvsadm -Sn > $TCTMP/tables.backup
	export LOGDIR=$TCTMP/log
	mkdir -p $LOGDIR
}

tc_setup

test_clear_virtual_table
test_restore_and_dump_vtable
test_add_virtual_server
test_add_real_server
test_edit_virtual_server
test_edit_real_server
test_delete_virtual_server
test_delete_real_server

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
### File : stunnel.sh                                                          ##
##
### Description: This testcase tests the stunnel package                       ##
##
### Author: Gopal Kalita <gokalita@in.ibm.com>                                 ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
STUNNEL_TESTS_DIR="${LTPBIN%/shared}/stunnel"
OPENSSLCONF=/etc/pki/tls/openssl.cnf
REQUIRED="openssl awk sed expect"
CAKEY=demoCA/private/stunnel.pem
COUNTRY=In
STATE=Karnataka 
CITY=Bangalore
ORG=IBM
ORGUNIT=LTC
CN=localhost
EMAIL=stunnel@test.com

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED

	rpm -q "stunnel" >$stdout 2>$stderr	
	tc_break_if_bad $? "stunnel not installed" || return

	[ -f $OPENSSLCONF ]
	tc_break_if_bad $? "No openssl config found" || return
	cp $OPENSSLCONF ${OPENSSLCONF}.bak

	pushd $STUNNEL_TESTS_DIR &>/dev/null
	mkdir -p demoCA/private
	mkdir -p demoCA/newcerts
	touch demoCA/index.txt
	
	touch /test_file
	echo "Testing stunnel" >> /test_file

	### Modify conf file to gen certs in ./demoCA dir ###
	pat1=`grep "# Where everything is kept" $OPENSSLCONF | awk '{print $3}'`
	sed -i "s:$pat1:$STUNNEL_TESTS_DIR/demoCA:" $OPENSSLCONF
 
	# Generating the cert
	echo "Creating new certs..."
	./gen_stunnel_pem.exp $CAKEY $COUNTRY $STATE $CITY $ORG $ORGUNIT $CN $EMAIL >$stdout 2>$stderr 
	tc_break_if_bad $? "Failed to create stunnel.pem" || return       
	
	cp -f ./demoCA/private/stunnel.pem /etc/stunnel

	# The stunnel.pem file contains your key (private data) and certificate (public data). 
	# In order for stunnel to start automatically without requiring a password, the key is 
	# created without a password. This means that anyone who can read this file can compromise 
	# your SSL security. So this file must be readable only by root, or the user who runs stunnel. 
	chmod 600 /etc/stunnel/stunnel.pem

	####Configuring rsync
	[ -f /etc/rsyncd.conf ] && \
	mv -f /etc/rsyncd.conf /etc/rsyncd.conf.bak

	#create the rsync conf file
        cat <<-EOF > /etc/rsyncd.conf
		use chroot = yes
		uid = root
		gid = root
		max connections = 10
		timeout = 600
		read only = yes
		path = /opt/fiv/ltp/testcases/fivextra/stunnel/
		comment = server Backups
		hosts allow = 127.0.0.1
		read only = no
		ignore nonreadable = yes
		refuse options = checksum
		dont compress = *
	EOF

	### Configuring stunnel ###
	cp -p /etc/services /etc/services.bak
	# rsync over stunnel
	echo "ssync 273/tcp" >> /etc/service
	#let Local connections pass on the ssync port
	cp -p /etc/hosts.allow /etc/hosts.allow.bak
	echo "ssync : LOCAL" >> /etc/hosts.allow

	#backup stunnel.conf
	[ -f /etc/stunnel/stunnel.conf ] && \
	mv -f /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.bak

	#create the stunnel conf file
	cat <<-EOF > /etc/stunnel/stunnel.conf
		cert = /etc/stunnel/stunnel.pem
		client = yes
		pid = /var/run/stunnel.pid
		debug = 7
		foreground = yes
		[ssync]
		accept = 273
		connect = 127.0.0.1:873
	EOF
	netstat -tulpn | grep -i :273 | grep stunnel >$stdout 2>$stderr
        if [ $? -eq 0 ]; then
                tc_info "bind: Adrress Already in use. kill existing stunnel process."
                kill -9 `ps -aux | grep stunnel | awk '{print $2'} | head -1`
                sleep 05
        fi
	# start the stunnel service
	# There is no init script for stunnel.
	# https://bugzilla.redhat.com/show_bug.cgi?id=455815
	stunnel >$stdout 2>stderr.txt &
	sleep 10
	pid_stunnel=$!
	for((i=0;i<10;i++))
        do
                sleep 60
                cat stderr.txt | grep -Eq "Created pid file"
                RC=$?
                [ x$RC == x0 ] &&  break
        done
	[ $pid_stunnel -eq `cat /var/run/stunnel.pid | grep $pid_stunnel` ]
	tc_break_if_bad_rc $? "Failed to start stunnel" || return
	popd &>/dev/null
}


function tc_local_cleanup()
{
	pushd $STUNNEL_TESTS_DIR &>/dev/null
	mv ${OPENSSLCONF}.bak $OPENSSLCONF
	rm -rf demoCA
	[ -f /etc/rsyncd.conf.bak ] && \
	mv -f /etc/rsyncd.conf.bak /etc/rsyncd.conf
	[ -f  /etc/stunnel/stunnel.conf.bak ] && \
	mv -f /etc/stunnel/stunnel.conf.bak /etc/stunnel/stunnel.conf
	mv -f /etc/services.bak /etc/services
	mv -f /etc/hosts.allow.bak /etc/hosts.allow
	rm -f /test_file
	rm -f test_file
	rm -f /root/.ssh/id_rsa*
	rm -f nohup*
	kill -9 $pid_stunnel &>/dev/null
	popd &>/dev/null
}

## Test function ##

function run_test()
{
	pushd $STUNNEL_TESTS_DIR &>/dev/null
	tc_register "Run rsync through stunnel"

	ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa >/dev/null
        cat /root/.ssh/id_rsa.pub >>/root/.ssh/authorized_keys

	expect -c "spawn rsync -a -R --numeric-ids /test_file root@localhost:$STUNNEL_TESTS_DIR; expect \"Are you sure you want to continue connecting (yes/no)?\" { send \"yes\r\" }; expect eof"

	cat test_file | grep -q "Testing stunnel" >$stdout 2>$stderr
	tc_pass_or_fail $? "rsync through stunnel test failed"
	popd &>/dev/null
}

#
# main
#
TST_TOTAL=1
tc_run_me_only_once
tc_setup && run_test

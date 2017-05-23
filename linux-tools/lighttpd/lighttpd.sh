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
## File :        lighttpd.sh
##
## Description:  Check that lighttpd-webserver can serve up HTML and CGI web pages.
##
## Author:	Pravin S. Gaikar
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
SDIR=${LTPBIN%/shared}/lighttpd

version=""	# Will be set to "ipv6" as appropriate for the tc_* utilities that
		# need it. Calculated based on IPVER env var and IPv6 availability.

TEST_PAGE1=""
TEST_PAGE2=""
TEST_PAGE3=""
TEST_PAGE4=""
RUN_DIR=""

certloc=/etc/ssl/private

docroot=/var/www/lighttpd/
cgidocroot=$docroot/cgi-bin

SECRET_MESSAGE="hello"

tester1=tester.pl
tester2=tester.sh
tester3=tester.php
perlbin=$(which perl)
phpbin=$(which php)

lightyconffile=/etc/lighttpd/lighttpd.conf

httpport="80"
httpsport="443"

                                                                                                                                                              
################################################################################
# the testcase functions
################################################################################

#
# tc_local_setup
#
function tc_local_setup()
{
       tc_get_os_arch                                                                                
       if [ "$TC_OS_ARCH" = "ppcnf" ]                                                                
         then                                                                                                    
            cp $SDIR/lighttpd.conf $SDIR/lighttpd_backup.conf                                       
            sed -i '/"mod_fastcgi"/s/^/#/' $SDIR/lighttpd.conf                                            
            sed -i '/include_shell "find/s/^/#/' $SDIR/lighttpd.conf                                     
	    sed -i '/fastcgi.server/,+7d' $SDIR/lighttpd.conf
       fi                                                                                          
	tc_info "port 80 at entry to tc_local_setup: $(netstat -ltpn | grep ':80 ')"
	
	tc_service_status httpd
	if [ $? -eq 0 ]; then
		httpd_cleanup=1;
		tc_service_stop_and_wait httpd
	fi

	server_host=localhost
        mkdir -p $cgidocroot
        tc_break_if_bad $? "Unable to create the directory '$cgidocroot'." || return

        mkdir -p $certloc
        tc_break_if_bad $? "Unable to create the directory '$certloc'." || return

	HTTPS_TEST=no
	tc_executes /usr/bin/openssl && HTTPS_TEST=yes
	
	tc_ipv6_info

	[ "$TC_IPV6_ADDRS" ] || [ "$IPVER" != "ipv6" ]
	tc_break_if_bad $? "Unable to support requested IPv6 test mode" || exit

	# Copy files to the web root directory.
        RUN_DIR="${TCTMP}"
        TEST_PAGE1="$cgidocroot/$tester1"
        cat > $TEST_PAGE1 <<-EOF
		#!$perlbin
		print "Content-type: Text/html\r\n\r\n";
		print "$SECRET_MESSAGE\r\n\r\n";
	EOF
	chmod a+rwx $TEST_PAGE1

        TEST_PAGE2="$docroot/${TCID}$$.html"
        cat > $TEST_PAGE2 <<-EOF
                <html>
                <body>
                <p>
                $SECRET_MESSAGE
                </p>
                </body>
                </html>
	EOF

        TEST_PAGE3="$cgidocroot/$tester2"
        cat > $TEST_PAGE3 <<-EOF
		#!/bin/bash
		# Simple CGI script for testing purposes
		SECRET_MESSAGE=$SECRET_MESSAGE
		cat <<-EOT
		content-type: text/html
		
		<html><body>
		<h1>Hello \$REMOTE_ADDR! Welcome to My Dynamic Web Page</h1>
		<p>Your query string was "\$(echo \$QUERY_STRING)"
		<p>Secret Message "\$SECRET_MESSAGE"
		<p>The time is \$(date)
		<p>The environment variables are ...
		<pre>
		\$(env)
		</pre>
		</body></html>
		EOT
	EOF
	chmod a+rwx $TEST_PAGE3

        TEST_PAGE4="$cgidocroot/$tester3"
        cat > $TEST_PAGE4 <<-EOF
                <html>
                <body>
                <?php
                echo "$SECRET_MESSAGE";
                ?>
                </body>
                </html>
	EOF
        chmod a+rwx $TEST_PAGE4

	cp -p $lightyconffile "$lightyconffile"_save
	cp $SDIR/lighttpd.conf $lightyconffile
	cp -p /etc/lighttpd/modules.conf /etc/lighttpd/modules.conf_save
	cp $SDIR/modules.conf /etc/lighttpd/modules.conf

	 [ "$HTTPS_TEST" = "yes" ] && {
                [ -f "$SDIR/cert/server.pem" ]
                tc_break_if_bad $? "Unable to find the cert file '$SDIR/cert/server.pem'." || return
                cp $SDIR/cert/server.pem $certloc/lighttpd.pem
        }

        return 0
}

#
# tc_local_cleanup              cleanup unique to this testcase
#
function tc_local_cleanup()
{

	tc_info "port 80 at entry to tc_local_cleanup: $(netstat -ltpn | grep ':80 ')"

	[ "$lighttpd_started" = "yes" ] && tc_service_stop_and_wait lighttpd
        rm -f $TEST_PAGE1  $TEST_PAGE2  $TEST_PAGE3 $TEST_PAGE4 $certloc/lighttpd.pem &>/dev/null
	
	[ -f "$lightyconffile"_save ] && mv "$lightyconffile"_save $lightyconffile
	[ -f /etc/lighttpd/modules.conf_save ] && mv /etc/lighttpd/modules.conf_save /etc/lighttpd/modules.conf

	if [ $httpd_cleanup ]; then
		tc_service_start_and_wait httpd
	fi

        [ -f $SDIR/lighttpd_backup.conf ] && mv -f $SDIR/lighttpd_backup.conf $SDIR/lighttpd.conf
	tc_info "port 80 at exit from tc_local_cleanup: $(netstat -ltpn | grep ':80 ')"
         
	
}

#
# test01        installation check
#
function test01()
{
        local savedir
        local x
        local started=""

        tc_register "Installation check and start webserver"

      tc_check_package lighttpd
        tc_fail_if_bad $? "lighttpd not installed properly" || return

        # port must not be in use $version
	tc_wait_for_inactive_port $httpport 10 $version 
        tc_break_if_bad $? "port $httpport already in use" || return

        if [ "$HTTPS_TEST" = "yes" ]; then
		tc_wait_for_inactive_port $httpsport 10 $version 
                tc_break_if_bad $? "port $httpsport already in use" || return
        fi

        # Start lighttpd-webserver
        savedir=${PWD}
        cd $RUN_DIR
	tc_info "Starting lighttpd."
	lighttpd_started="yes";
	tc_service_start_and_wait lighttpd
        cd $savedir

	tc_wait_for_active_port $httpport 10 $version 
	tc_fail_if_bad $? "lighttpd not listening on $version port $httpport" || return

       	if [ "$HTTPS_TEST" = "yes" ]; then
		tc_info "also testing https"
		tc_wait_for_active_port $httpsport 10 $version 
		tc_fail_if_bad $? "lighttpd not listening on $version port $httpsport" || return
	fi

	tc_pass
}

#
# test02        fetch web page via http/https
#
function test02()
{
	while [ $1 ]; do
        [ $1 == ipv4 ] && server_host=localhost4
        [ $1 == ipv6 ] && server_host=localhost6
        
	tc_register "get web page from $server_host (http $server_host)"

       	# get the page from web sever via http.
       	fivget http $server_host $httpport ${TCID}$$.html >$stdout 2>$stderr
       	tc_fail_if_bad $? "failed to get http response from server" || return

        # check for expected content
        grep -q "$SECRET_MESSAGE" $stdout 2>$stderr
	tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (http $server_host)."

       	if [ "$HTTPS_TEST" = "yes" ]; then
		((++TST_TOTAL))
		tc_register "get web page from $server_host (https $server_host)"

        	# get the page from web sever via https.
        	fivget https $server_host $httpsport ${TCID}$$.html >$stdout 2>$stderr
        	tc_fail_if_bad $? "failed to get https response from server" || return

		# check for expected content
		grep -q "$SECRET_MESSAGE" $stdout 2>$stderr
		tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (https $server_host)."
	fi
	shift
	done
}

#
# test03        bash CGI test
#
#
function test03()
{
	while [ $1 ]; do
        [ $1 == ipv4 ] && server_host=localhost4
        [ $1 == ipv6 ] && server_host=localhost6
	tc_register "bash CGI test on $server_host (http $server_host)"

	# get cgi responses via http using bash 
	fivget http $server_host $httpport cgi-bin/$tester2 >$stdout  2>$stderr
	tc_fail_if_bad $? "failed to get http cgi response from server" || return

	# check the response
        grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
	tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (http $server_host)."

	if [ "$HTTPS_TEST" = "yes" ]; then
		((++TST_TOTAL))
		tc_register "bash CGI test on $server_host (https $server_host)"

		# get cgi responses via https using bash 
		fivget https $server_host $httpsport cgi-bin/$tester2 >$stdout  2>$stderr
		tc_fail_if_bad $? "failed to get https cgi response from server" || return

		# check the response
		grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
		tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (https $server_host)."

	fi
	shift
	done
}

#
# test04        perl CGI test
#
#
function test04()
{
        [ $perlbin ] || {
		((--TST_TOTAL))
		return 0
	}
	
	while [ $1 ]; do
        [ $1 == ipv4 ] && server_host=localhost4
        [ $1 == ipv6 ] && server_host=localhost6

        tc_register "perl CGI test on $server_host (http $server_host)"

	# get cgi responses via http using perl
	fivget http $server_host $httpport cgi-bin/$tester1 >$stdout  2>$stderr
	tc_fail_if_bad $? "failed to get http cgi response from server" || return

	# check the response
        grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
	tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (http $server_host)."

	if [ "$HTTPS_TEST" = "yes" ]; then
		((++TST_TOTAL))
		tc_register "perl CGI test on $server_host (https $server_host)"

		# get cgi responses via https using perl
		fivget https $server_host $httpsport cgi-bin/$tester1 >$stdout  2>$stderr
		tc_fail_if_bad $? "failed to get https cgi response from server" || return

		# check the response
		grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
		tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (https $server_host)."
	fi
	shift
	done
}



#
# test05        php FastCGI test
#
#
function test05()
{
	while [ $1 ]; do
        [ $1 == ipv4 ] && server_host=localhost4
        [ $1 == ipv6 ] && server_host=localhost6
        tc_register "php FastCGI test on $server_host (http $server_host)"

        # get fastcgi responses via http using php
        fivget http $server_host $httpport cgi-bin/$tester3 >$stdout  2>$stderr
        tc_fail_if_bad $? "failed to get http cgi response from server" || return

        # check the response
        grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
        tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (http $server_host)." || return

        if [ "$HTTPS_TEST" = "yes" ]; then
                ((++TST_TOTAL))
                tc_register "php FastCGI test on $server_host (https $server_host)"

                # get fastcgi responses via https using php
                fivget https $server_host $httpsport cgi-bin/$tester3 >$stdout  2>$stderr
                tc_fail_if_bad $? "failed to get https cgi response from server" || return

                # check the response
                grep -q "$SECRET_MESSAGE" $stdout  2>$stderr
                tc_pass_or_fail $? "expected to see: \"$SECRET_MESSAGE\" in the html file (https $server_host)."
        fi
	shift
	done
}


################################################################################
# Main
################################################################################

TST_TOTAL=4

tc_setup


[ "$PHP5_FASTCGI" = "yes" ] &&
{     # run only fastcgi test on behalf of php5-fastcgi
    TST_TOTAL=2
    test01 || exit
    test05 ipv4 ipv6
    exit
}

test01 || exit
test02 ipv4 ipv6
test03 ipv4 ipv6
test04 ipv4 ipv6

################################################################################
# End Of Main
################################################################################

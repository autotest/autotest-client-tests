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
### File :        php.sh
##
### Description:  Test that php are used properly
##
### Author:       Gong Jie <gongjie@cn.ibm.com>
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

PHP_TESTS_DIR=${LTPBIN%/shared}/php/php-tests

# remember to stop any web server we start
STOP_APACHE2=no
STOP_LIGHTTPD=no
STOP_HTTPD=no

#
# local setup
#
function tc_local_setup()
{
	tc_exec_or_break sed which grep || return
	export TEST_PHP_EXECUTABLE=$(which php 2>/dev/null)
	export http_proxy=

	tc_get_os_arch
	if [ "$TC_OS_ARCH" = "ppc64" -o "$TC_OS_ARCH" = "ppc64le" -o "$TC_OS_ARCH" = "ppc" ];then
		cp ${PHP_TESTS_DIR}/../exclude_list ${PHP_TESTS_DIR}/../exclude_list-bk
		cat <<-EOF >> ${PHP_TESTS_DIR}/../exclude_list
		ext/standard/tests/strings/bug47842.phpt
		ext/standard/tests/strings/htmlspecialchars_decode_variation2.phpt
		ext/standard/tests/strings/vprintf_variation15_64bit.phpt
		ext/standard/tests/strings/vsprintf_variation15_64bit.phpt
		ext/standard/tests/math/decbin_variation1_64bit.phpt
		ext/standard/tests/math/dechex_variation1_64bit.phpt
		ext/standard/tests/math/decoct_variation1_64bit.phpt
EOF
		# https://bugzilla.linux.ibm.com/show_bug.cgi?id=71624#c6
		cp ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt.orig
		sed -i 's/string(16) "Unknown error 58"/string(27) "File locking deadlock error"/' ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt
		# https://bugzilla.linux.ibm.com/show_bug.cgi?id=118786#c6
		if [ `$TEST_PHP_EXECUTABLE -v|cut -d"." -f2|head -1` -lt 7 ]; then
		echo "		tests/lang/operators/bitwiseShiftLeft_basiclong_64bit.phpt
		tests/lang/operators/bitwiseShiftLeft_variationStr_64bit.phpt
		tests/lang/operators/bitwiseShiftRight_basiclong_64bit.phpt
		tests/lang/operators/bitwiseShiftRight_variationStr.phpt" >> ${PHP_TESTS_DIR}/../exclude_list
		fi
	fi

 	#==================================================================================
        # bitwise shift tests will be excluded on ppc64 alone.
        # This issue was found in upstream as well and is planned to fix in 5.7
        #==============================================================================



        #===========================================================================================================================================
        # On s390x arch below tests were failing because of BSO authentication, so excluding tests which are trying to connect outside the world
        #===========================================================================================================================================

	# If server is not connection to the outside world, exclude the below tests
	ping -c 2 google.com >/dev/null 2>&1 
	if [ $? -ne 0 ]; then
	        if [ "$TC_OS_ARCH" = "s390x" ];then
        	        cp ${PHP_TESTS_DIR}/../exclude_list ${PHP_TESTS_DIR}/../exclude_list-bk
                	cat <<-EOF >> ${PHP_TESTS_DIR}/../exclude_list
	                ext/standard/tests/strings/bug47842.phpt
        	        ext/standard/tests/strings/htmlspecialchars_decode_variation2.phpt
                	ext/standard/tests/strings/vprintf_variation15_64bit.phpt
	                ext/standard/tests/strings/vsprintf_variation15_64bit.phpt
        	        ext/standard/tests/math/decbin_variation1_64bit.phpt
                	ext/standard/tests/math/dechex_variation1_64bit.phpt
	                ext/standard/tests/math/decoct_variation1_64bit.phpt
        	        ext/standard/tests/strings/substr_compare.phpt
                	ext/standard/tests/file/file_get_contents_error001.phpt
	                ext/standard/tests/network/http-stream.phpt
			ext/standard/tests/network/gethostbyname_error004.phpt
                        ext/standard/tests/php_ini_loaded_file.phpt
                        ext/standard/tests/network/getmxrr.phpt

EOF
  	      fi
	fi
	# Renaming the functions in the exclude list
	for  i in `cat ${PHP_TESTS_DIR}/../exclude_list`
	do
 	     	mv  ${PHP_TESTS_DIR}/${i} ${PHP_TESTS_DIR}/${i}$$
	done
	return 0


}

#
# local cleanup
#
function tc_local_cleanup()
{	
	if [ "$STOP_APACHE2" = "yes" ];then
		tc_service_stop_and_wait apache2;
		[ -f $TCTMP/saved-index.html ] &&    # restore original web page, if any
		cp $TCTMP/saved-index.html /var/www/index.html
	elif [ "$STOP_LIGHTTPD" = "yes" ]; then
		tc_service_stop_and_wait lighttpd ;
		[ -f $TCTMP/saved-index.html ] &&    # restore original web page, if any
		cp $TCTMP/saved-index.html /var/www/lighttpd/index.html 
	elif [ "$STOP_HTTPD" = "yes" ];then
		tc_service_stop_and_wait httpd;
		[ -f $TCTMP/saved-index.html ] &&    # restore original web page, if any
		cp $TCTMP/saved-index.html /var/www/html/index.html
	fi
	[ -f $TCTMP/php.ini ] && mv $TCTMP/php.ini /etc/

# Putting back the functions in exclude list.

	for  i in `cat ${PHP_TESTS_DIR}/../exclude_list`
	do
	       mv ${PHP_TESTS_DIR}/${i}$$ ${PHP_TESTS_DIR}/$i
	done
	[ -f ${PHP_TESTS_DIR}/../exclude_list-bk ] && mv ${PHP_TESTS_DIR}/../exclude_list-bk ${PHP_TESTS_DIR}/../exclude_list
	[ -f ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt.orig ] && mv ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt.orig ${PHP_TESTS_DIR}/ext/sockets/tests/socket_strerror.phpt
}

#
# Function run_tests
#
# Description   - run php testcases
#
# Return        - zero on success
#               - return value from testcase on failure ($RC)
function run_tests()
{
	local dir="$1"
	local result
	(cd $PHP_TESTS_DIR && $TEST_PHP_EXECUTABLE run-tests.php $dir) \
		&>$TCTMP/run_tests.out
	result=$?
	sed -e "/FAILED TEST SUMMARY/,\$w $stderr" $TCTMP/run_tests.out >&/dev/null
	return $result
}

#
# test1:  install_check         Installation check
#
function install_check()
{
	tc_register "php installation check"
	tc_executes php
	tc_pass_or_fail $? "php not properly installed"
}

#
# test2: run_base_test          Basic language test
#
function run_base_test
{
	tc_register "basic language test"
	run_tests tests >$stdout 2>$stderr
	RC="$?"
	if [ "$RC" -eq 0 ];then
		cat /dev/null >$stderr
	fi
	tc_pass_or_fail $RC
}

#
# test3: run_ext_test           External functions test
#
function run_ext_test
{
	local module="$1"
	tc_register "$module functions test"

	if [ -d $PHP_TESTS_DIR/ext/$module/tests ] ; then
		run_tests ext/$module/tests >$stdout 2>$stderr
		 RC="$?"
	         if [ "$RC" -eq 0 ];then
        	        cat /dev/null >$stderr
         	 fi

	elif [ -d $PHP_TESTS_DIR/addons/$module/tests ]; then
		run_tests addons/$module/tests >$stdout 2>$stderr
	else 
		tc_pass_or_fail 9 "$module testcases not found"
		return
	fi

	tc_pass_or_fail $?

}

function_have_http_server()
{
	tc_executes lighttpd && {
		tc_service_restart_and_wait lighttpd
		tc_wait_for_active_port 80
		tc_break_if_bad $? "Cannot start lighttpd" || return
		STOP_LIGHTTPD=yes
		return
	}
	tc_executes apache2 && {
		tc_service_restart_and_wait apache2
		tc_wait_for_active_port 80
		tc_break_if_bad $? "Cannot start apache" || return
		STOP_APACHE2=yes
		return
	}
	tc_executes httpd && { 
		 tc_service_restart_and_wait httpd
		 tc_wait_for_active_port 80
		 tc_break_if_bad $? "Cannot start httpd" || return 
		 STOP_HTTPD=yes
		 return
	}
}

#
# run curl test. requires web server.
#
function test_curl()
{
	function_have_http_server || {
		tc_info "skipping curl test because no web server available"
		((--TST_TOTAL))
		return 0
	}

	tc_register "curl functions test"
	
	#
	# web page to fetch	(preserve leading tabs!)
	#
	if [ "$STOP_HTTPD" == "yes" ]
	then
		[ -f /var/www/html/index.html ] &&	# save original web page, if any
			cp /var/www/html/index.html $TCTMP/saved-index.html
		cat <<-EOF > /var/www/html/index.html
			Sample page $$
		EOF
		
	elif [ "$STOP_APACHE2" == "yes" ]
	then
		[ -f /var/www/index.html ] &&	# save original web page, if any
			cp /var/www/index.html $TCTMP/saved-index.html
		cat <<-EOF > /var/www/index.html
			Sample page $$
		EOF
	elif [ "$STOP_LIGHTTPD" == "yes" ]
	then
		[ -f /var/www/lighttpd/index.html ] &&	# save original web page, if any
			cp /var/www/lighttpd/index.html $TCTMP/saved-index.html
		cat <<-EOF > /var/www/lighttpd/index.html
			Sample page $$
		EOF
	fi
	#
	# php curl script	(preserve leading tabs!)
	#
	cat <<-EOF > $TCTMP/curl.php
		<?php
		\$testpage = "http://localhost";
		\$ch = curl_init(\$testpage);
		\$fp = fopen("$TCTMP/results.txt", "w");
		curl_setopt(\$ch, CURLOPT_FILE, \$fp);
		curl_setopt(\$ch, CURLOPT_HEADER, 0);
		curl_exec(\$ch);
		curl_close(\$ch);
		fclose(\$fp);
		echo file_get_contents("$TCTMP/results.txt");
		unlink("$TCTMP/results.txt");
		?>
	EOF

	chmod +x $TCTMP/curl.php
	php $TCTMP/curl.php >$stdout 2>$stderr &&
	grep -q "Sample page $$" $stdout
	tc_pass_or_fail $? "did not get web page"
}

function fix_socket_bind_test()
{
	# Fix socket_bind.phpt test - Bug 85552
	function_have_http_server && { 
	    [ -f $PHP_TESTS_DIR/ext/sockets/tests/socket_bind.phpt ] && \
	    sed -i '/www.php.net/ s//127.0.0.1/' \
		$PHP_TESTS_DIR/ext/sockets/tests/socket_bind.phpt
	}
}
	
#
# main
#
tc_setup

install_check || exit
tc_info "Visit php bugs tracking system at the followin URL"
tc_info "http://bugs.php.net/"

if [ "$#" = "0" ]
then
	TST_TOTAL=3
	run_base_test
	run_ext_test standard
else
	TST_TOTAL=2
	if [ "$1" = "curl" ]
	then
		test_curl
	else
		[ "$1" = "sockets" ] && fix_socket_bind_test
		run_ext_test "$1"
	fi
fi
exit 0

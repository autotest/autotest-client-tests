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
## File:		prelink.sh
##
## Description:	Test the prelink package
##
## Author:	Athira Rajeev <atrajeev@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/prelink
source $LTPBIN/tc_utils.source
TSTDIR=${LTPBIN%/shared}/prelink/

REQUIRED="execstack prelink"
TST_TOTAL=10

################################################################################
# testcase functions
################################################################################

function savelibs()
{	
	# Save libs and bins to .orig
	for i in $LIBS $BINS; 
	do
	cp -p $i $i.orig;
	done
}

function unlink()
{
	tc_register "unlink with -u and -y options"

	pushd $TSTDIR &>/dev/null

	for i in $LIBS $BINS; do
		# copy prelinked file to .new,
		# run -u to undo prelink,
		# compare with the original file
		cp -p $i $i.new
		$PRELINK -u $i.new 
		tc_fail_if_bad $? "prelink -u on $i failed" || return

		cmp -s $i.orig $i.new 
		tc_fail_if_bad $? "prelink -u on $i failed, $i changed after prelink" || return

		rm -f $i.new

		# run -y to verify the file
		# hasn't hanged after prelink
		$PRELINK -y $i > $i.new 
		tc_fail_if_bad $? "prelink -y on $i failed" || return

		cmp -s $i.orig $i.new 
		tc_fail_if_bad $? "prelink -y on $i failed, $i changed after prelink" || return

		rm -f $i.new
	done

	restore
	popd &>/dev/null

	tc_pass
}

function tc_local_setup()
{
	tc_exec_or_break $REQUIRED || return

	# /etc/sysconfig/prelink file is not appicable on ubuntu, Ubuntu has /usr/sbin/prelink 
	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -eq 0 ];then  # Start of OS check
		tc_exist_or_break /etc/prelink.conf /usr/sbin/prelink || return
	else
		tc_exist_or_break /etc/prelink.conf /etc/sysconfig/prelink || return
	fi

	tc_get_os_arch
	userlibdir=/usr/lib
	libdir=/lib/
	[ $TC_OS_ARCH = "x86_64" ] || [ $TC_OS_ARCH = "ppc64" ] || [ $TC_OS_ARCH = "s390x" ] \
        && userlibdir=/usr/lib64/ && \
		libdir=/lib64/
	# On Ubuntu usrlib and lib paths are diff, so modified the code based on that
	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -eq 0 ];then  # Start of OS check
		 userlibdir="/usr/lib/*-linux-gnu/"
		 libdir="/lib/*-linux-gnu/"
	fi

	PRELINK="/usr/sbin/prelink -c ./prelink.conf -C ./prelink.cache --ld-library-path=."

	cat >> $TSTDIR/prelink.conf <<-EOF
	$TSTDIR
	$userlibdir
	$libdir
	EOF
}

function tc_local_cleanup()
{
	pushd $TSTDIR &>/dev/null	
	rm -rf prelink.cache
	rm -rf $TSTDIR/prelink.conf

	rm -rf *.log
	popd &>/dev/null

}

function restore()
{
	# To restore the files to original
	for i in $LIBS $BINS;
        do
        mv $i.orig $i
        done
}

function test01()
{
	tc_register "prelink test on shared libraries"

	pushd $TSTDIR &>/dev/null

	BINS=$1
	LIBS="$2 $3"
	
	savelibs
	
	# Execute prelink on binary reloc1
	echo $PRELINK ${PRELINK_OPTS--vm} $BINS > $BINS.log
	$PRELINK ${PRELINK_OPTS--vm} $BINS >> $BINS.log 2>&1 

	grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` $BINS.log
	if [ $? -eq 0 ]; then
		tc_fail "prelink on $BINS failed" || return	
	fi

	LD_LIBRARY_PATH=. ./$BINS 1>$stdout 2>$stderr
	tc_fail_if_bad $? "Failed to execute the binary $BINS" || return

	readelf -a $BINS >> $BINS.log 2>$stderr
	grep -wq .gnu.prelink_undo $BINS.log
	tc_fail_if_bad $? "prelink undo section not present" || return

	# So that it is not prelinked again
	chmod -x $BINS
	
	popd &>/dev/null

	tc_pass
}

function test02()
{

	tc_register "prelink doesnot fail on bogus library dependency"
	
	pushd $TSTDIR &>/dev/null

	BINS="cycle1"
	LIBS="cycle1lib1.so cycle1lib2.so"
	
	savelibs

	# Execute prelink on binary cycle1
	echo $PRELINK ${PRELINK_OPTS--vm} $BINS > $BINS.log
	$PRELINK ${PRELINK_OPTS--vm} $BINS >> $BINS.log 2>&1

	grep -v 'has a dependency cycle' $BINS.log | grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` 
	if [ $? -eq 0 ]; then
		tc_fail "prelink failed on bogus library dependency" || return

	fi
	
	# cycle1lib1.so libs are not part of Ubuntu, so excluding this test
	# This is only for test purpose
	grep -i "ubuntu" /etc/*-release >/dev/null 2>&1
        if [ $? -ne 0 ];then  # Start of OS check
		grep -q "^`echo $PRELINK | sed 's/ .*$/: .*has a dependency cycle/'`" $BINS.log
		tc_fail_if_bad $? "prelink failed on cycle1" || return
	fi

	LD_LIBRARY_PATH=. ./$BINS 
	tc_fail_if_bad $? "Failed to execute the binary" || return

	# So that it is not prelinked again
	chmod -x $BINS

	restore
	popd &>/dev/null	

	tc_pass
}

function test03()
{
	tc_register "binaries compiled by g++ testing with -R"

	pushd $TSTDIR &>/dev/null

	BINS="layout1"
	LIBS=layout1lib*.so

	savelibs

	# Execute prelink on layout1
	echo $PRELINK ${PRELINK_OPTS--vR} $BINS > $BINS.log
	$PRELINK ${PRELINK_OPTS--vR} $BINS >> $BINS.log 2>$stderr

	grep -q ^`echo $PRELINK | sed 's/ .*$/: /'` $BINS.log
	if [ $? -eq 0 ]; then
                tc_fail "prelink failed on layout1" || return

        fi

	LD_LIBRARY_PATH=. ./$BINS
	tc_fail_if_bad $? "Failed to execute the binary" || return

	readelf -a $BINS >> $BINS.log 2>$stderr
        grep -wq .gnu.prelink_undo $BINS.log
        tc_fail_if_bad $? "prelink section not present" || return

	# So that it is not prelinked again
	chmod -x $BINS

	popd &>/dev/null

	tc_pass	
}

function test04()
{
	tc_register "execstack --set-execstack"
	
	pushd $TSTDIR &>/dev/null

	execstack -s reloc1 1>$stdout 2>$stderr
	tc_pass_or_fail $? "execstack -s failed"

	tc_register "execstack --clear-execstack"
	execstack -c cycle1 1>$stdout 2>$stderr
	tc_pass_or_fail $? "execstack -c failed"

	tc_register "execstack --query"
	execstack -q reloc1 cycle1 1>$TCTMP/out 2>$stderr
	grep -q "X reloc1" $TCTMP/out && grep -q "\- cycle1" $TCTMP/out
	tc_pass_or_fail $? "execstack -q failed"
}
	
####################################################################################
# MAIN
####################################################################################

tc_setup

test01 reloc1 reloc1lib1.so reloc1lib2.so
unlink
test01 shuffle1 shuffle1lib1.so shuffle1lib2.so
unlink
test02
test03
unlink
test04

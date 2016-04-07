#!/bin/bash
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
# File:		gawk.sh
#
# Description:	Test gawk package
#
# Author:	Robb Romans <robb@austin.ibm.com>
#		Gong Jie <gongjie@cn.ibm.com>
#
###########################################################################################

# source the utility functions
#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

TSTDIR=${LTPBIN%/shared}/gawk/gawk-tests
# global variables
#
REQUIRED="make cat cmp"
TST_TOTAL=1

################################################################################
# testcase functions
################################################################################

# Function:		runtests
#
# Description:		- exercise modified gawk "make check" tests
#
# Parameters:		- none
#
# Return		- zero on success
#			- return value from commands on failure
#
function runtests() {

# non architecture specific tests
local basic_tests="addcomma anchgsub argarray arrayparm arrayref arrymem1 \
	arrayprm2 arrayprm3 arryref2 arryref3 arryref4 arryref5 arynasty \
	arynocls aryprm1 aryprm2 aryprm3 aryprm4 aryprm5 aryprm6 aryprm7 \
	aryprm8 arysubnm asgext awkpath back89 backgsub childin clobber \
	clsflnam compare compare2 concat1 convfmt datanonl defref \
	delarprm delarpm2 dynlj eofsplit fldchg fldchgnf fmttest fnamedat \
	fnarray fnarray2 fnarydel fnaryscl fnasgnm fnmisc fnparydl \
	forsimp fsbs fsrs fstabplus funsemnl funsmnam funstack getline \
	getline2 getline3 getlnbuf getnr2tb getnr2tm gsubasgn gsubtest \
	gsubtst2 gsubtst3 gsubtst4 gsubtst5 hsprint inputred intest \
	intprec leaddig leadnl litoct longsub longwrds math membug1 \
	messages minusstr mmap8k nasty nasty2 negexp nested nfldstr \
	nfneg nfset nlfldsep nlinstr nlstrina noeffect nofmtch noloop1 \
	noloop2 nonl noparms nors nulrsend numindex numsubstr octsub ofmt \
	ofmtbig ofmtfidl ofmts onlynl opasnidx opasnslf paramdup paramtyp \
	parseme pcntplus prdupval prec printf0 printf1 prmarscl prmreuse \
	prt1eval prtoeval rand rebt8b1 rebt8b2 redfilnm regeq \
	reindops reparse resplit rs rsnul1nl rsnulbig rsnulbig2 rstest1 \
	rstest2 rstest3 rstest4 rstest5 rswhite scalar sclforin sclifin \
	sortempty splitargv splitarr splitdef splitvar splitwht sprintfc \
	strtod subslash substr swaplns synerr1 tradanch tweakfld uninit2 \
	uninit3 uninit4 uninitialized zeroe0 zeroflag"

# unix specific tests
local unix_tests="fflush getlnhd pid pipeio1 pipeio2 poundbang space strftlng"

# test gawk extended functionality
local gawk_ext_tests="argtest asort asorti badargs clos1way fieldwdth fsfwfs \
	gensub gnuops2 gnureops icasefs icasers igncdym igncfs ignrcase lint \
	match1 match2 manyfiles nondec posix procinfs regx8bit rebuf reint \
	shadow sort1 strtonum strftime"

local extra_tests="regtest inftest"

local inet_tests="inetechu inetecht inetdayu inetdayt"

local gentests_unused="gtlnbufv printfloat switch2"

# count total tests and set harness variable
set $basic_tests $unix_tests $gawk_ext_tests
TST_TOTAL=$#

# run each testcase
for tst in $basic_tests $unix_tests $gawk_ext_tests
do
	runtest $tst
done
}

function runtest()
{
	local tst="$1"

	# housekeeping
	tc_register "$tst"

	srcdir=. PATH_SEPARATOR=: make -f Makefile.am $tst >$stdout 2>$stderr
	tc_pass_or_fail $?
	rm -f _$tst
}

function tc_local_setup()
{
	#cd ${LTPBIN%/shared}/gawk/gawk_tests
	cd $TSTDIR

	# so make command doesn't get excited about mismatched timestamps
	if [ $TC_OS_ARCH = ppcnf ]; then
	        ntpdate pool.ntp.org 1>$stdout 2>$stderr
	        tc_break_if_bad $? "ntpdate failed, please update system date before running the test"
	else 
		tc_executes hwclock && hwclock --hctosys
	fi
	touch * 

	ln -s $(which gawk) ..
}

function tc_local_cleanup()
{
	rm -f ../gawk
}

####################################################################################
# MAIN
####################################################################################

# Function:	main
#
# Description:	- Execute all tests, report results
#
# Exit:		- zero on success
#		- non-zero on failure
#
tc_get_os_arch 
tc_setup
tc_exec_or_break $REQUIRED || exit

if [ ! -z "$1" ]
then
	runtest $1
else
	runtests
fi

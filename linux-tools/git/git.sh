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
## File :        git.sh
##
## Description:  Test the "git" package
##
## Author:       Gopal Kalita <gokalita@in.ibm.com>
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/git
source $LTPBIN/tc_utils.source
GIT_DIR="${LTPBIN%/shared}/git"
TESTS_DIR="${LTPBIN%/shared}/git/t"
REQUIRED="git grep sed"

function tc_local_setup()
{
tc_exec_or_break $REQUIRED || return
ln -s /usr/bin/git $GIT_DIR/git
ln -s /usr/share/git-core/templates/ $GIT_DIR/templates
ln -s /usr/share/doc/git-1.8.3.1/contrib/ $GIT_DIR/contrib
ln -s /usr/libexec/git-core/git-init $GIT_DIR/git-init
ln -s /usr/libexec/git-core/git-sh-i18n $GIT_DIR/git-sh-i18n
# The bin-wrappers has 19 files which are kind of config file for the actual
# testcases, but some path needs to be changed to run them in test machine.
pushd $GIT_DIR/bin-wrappers &> /dev/null
for file in `find . -type f`
do
     EXEC=`grep GIT_EXEC_PATH= $file`
     TEMPLATE=`grep GIT_TEMPLATE_DIR= $file`
     PERL=`grep GITPERLLIB= $file`
     wrappers=`grep bin-wrappers: $file` 

     sed -i "s|$EXEC|GIT_EXEC_PATH=\'/usr/libexec/git-core\'|" $file
     sed -i "s|$TEMPLATE|GIT_TEMPLATE_DIR=\'/usr/share/git-core/templates/\'|" $file
     sed -i "s|$PERL|GITPERLLIB=\'$GIT_DIR/perl/blib/lib\'|" $file
     sed -i "s|$wrappers|PATH=\'$GIT_DIR/bin-wrappers:\'\"\$PATH\"|" $file
done

for file in `find . -name "test*" -type f`
do 
     sed -i "s|\${GIT_EXEC_PATH}|$GIT_DIR|" $file
done

popd &> /dev/null

pushd $TESTS_DIR &> /dev/null
sed -i "s|--template=\$TEST_DIRECTORY/../templates/blt/|--template=/usr/share/git-core/templates/|" test-lib.sh
sed -i "s|GIT_EXEC_PATH=\$TEST_DIRECTORY/..|GIT_EXEC_PATH=/usr/libexec/git-core/|" test-lib.sh
sed -i "s|GIT_TEMPLATE_DIR=\$(pwd)/../templates/blt|GIT_TEMPLATE_DIR=/usr/share/git-core/templates|" test-lib.sh
sed -i "s|test -d ../templates/blt|test -d /usr/share/git-core/templates|" test-lib.sh
sed -i "s|../git >/dev/null|git >/dev/null|" t0000-basic.sh
sed -i "s|///\$TEST_DIRECTORY/../gitweb|////var/www/git|" gitweb-lib.sh
popd &> /dev/null

}
function tc_local_cleanup()
{
        unlink $GIT_DIR/git
        unlink $GIT_DIR/contrib
        unlink $GIT_DIR/git-init
        unlink $GIT_DIR/git-sh-i18n
}
function run_test()
{
pushd $TESTS_DIR &> /dev/null
TESTS=`ls | grep sh | grep t.[0-9]-* | grep -v -e trash -e directory -e cvs`
TST_TOTAL1=`echo $TESTS | wc -w`

for test in $TESTS;
do
  tc_register "Test $test"
  ./$test >$stdout 2>$stderr
  tc_pass_or_fail $? "Test $test fail"
done

popd &> /dev/null
}

#
#main
#

tc_setup
run_test

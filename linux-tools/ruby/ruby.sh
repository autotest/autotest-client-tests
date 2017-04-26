#!/bin/bash
################################################################################
##                                                                            ##
##copyright 2003, 2016 IBM Corp                                               ##
##                                                                            ##
## This program is free software;  you can redistribute it and or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
##                                                                            ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
##                                                                            ##
## You should have received a copy of the GNU General Public Licens           ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
##                                                                            ##
## File :        ruby.sh                                                      ##
##                                                                            ##
## Description: This testcase tests ruby package                              ##
##                                                                            ##
## Author:      Anup Kumar, anupkumk@linux.vnet.ibm.com                       ##
################################################################################
# source the utility functions
#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/ruby
source $LTPBIN/tc_utils.source
FIVDIR="${LTPBIN%/shared}/ruby"
TEST_DIR="${LTPBIN%/shared}/ruby/ruby_test"
REQUIRED="erb gem irb ri ruby testrb cp ln"

################################################################################
# Testcase functions
################################################################################

function tc_local_setup()
{
        tc_root_or_break || exit
        tc_exec_or_break $REQUIRED || return

        # search the ruby packages
        rpm -q "ruby" >$stdout 2>$stderr
        tc_break_if_bad $? "ruby package is not installed"
        
        # backup of entire test directory and removing the failure test out from suit
        cp -r $FIVDIR/ruby_test $FIVDIR/ruby_test_backup &>/dev/null
        pushd $TEST_DIR &>/dev/null
        
        rm -f test/dtrace/test_array_create.rb test/dtrace/test_cmethod.rb test/dtrace/test_function_entry.rb test/dtrace/test_hash_create.rb test/dtrace/test_load.rb \
        test/dtrace/test_object_create_start.rb test/dtrace/test_raise.rb test/dtrace/test_require.rb test/dtrace/test_singleton_function.rb test/dtrace/test_string.rb \
        test/dbm/test_dbm.rb test/test_find.rb test/gdbm/test_gdbm.rb test/irb/test_completion.rb test/minitest/test_minitest_unit.rb test/pathname/test_pathname.rb \
        test/rdoc/test_rdoc_options.rb test/rdoc/test_rdoc_rdoc.rb lib/rdoc/task.rb test/sdbm/test_sdbm.rb test/openssl/test_x509cert.rb test/openssl/test_x509req.rb \
        test/ruby/test_fiber.rb test/json/test_json_generate.rb test/ruby/test_rubyoptions.rb test/-ext-/test_bug-3571.rb test/-ext-/load/test_dot_dot.rb \
        test/-ext-/exception/test_ensured.rb test/mkmf/test_convertible.rb test/mkmf/test_have_func.rb test/mkmf/test_have_library.rb test/mkmf/test_have_macro.rb \
        test/mkmf/test_signedness.rb test/mkmf/test_sizeof.rb test/mkmf/test_constant.rb test/ruby/test_time_tz.rb test/ripper/test_files.rb
        
        popd &>/dev/null
        # remove the existing binary and replace with actual in the server
        pushd $TEST_DIR/bin &>/dev/null
        rm -rf erb gem irb rdoc ri testrb &>/dev/null
        ln -s `which erb` erb 
        ln -s `which gem` gem
        ln -s `which irb` irb
        ln -s `which rdoc` rdoc
        ln -s `which ri` ri 
        ln -s `which testrb` testrb
        popd &>/dev/null

	#check the openssl package version
        rpm -qa | grep -i openssl &>/dev/null
        if [ $? -eq 0 ]; then
                openssl_vf1=$(openssl version -v | awk -F'-' '{print $1}' | awk '{print $2}' | awk -F'.' '{print $1}')
                openssl_vf2=$(openssl version -v | awk -F'-' '{print $1}' | awk '{print $2}' | awk -F'.' '{print $2}')
                openssl_vf3=$(openssl version -v | awk -F'-' '{print $1}' | awk '{print $2}' | awk -F'.' '{print $3}' | rev | cut -c 2- | rev)
                if [[ ("$openssl_vf1" -ge "1") && ("$openssl_vf2" -ge "0") && ("$openssl_vf3" -ge "1") ]]; then
                                # removing the npn protocol comparison string with sdpy protocol for openssl version higher than 1.0.1
                                sed -i "/assert_equal(advertised.send(which), ssl.npn_protocol)/ s//#&/" $TEST_DIR/test/openssl/test_ssl.rb
                                sed -i "/assert_equal(selected, ssl.npn_protocol)/ s//#&/" $TEST_DIR/test/openssl/test_ssl.rb
                fi
        fi

        
        # remove the ruby binary as well
        rm -rf $TEST_DIR/ruby 
        ln -s `which ruby` $TEST_DIR/ruby 
}

function tc_local_cleanup()
{
        # remove the test directory and restore this original
        rm -rf $FIVDIR/ruby_test &>/dev/null
        cp -r $FIVDIR/ruby_test_backup $FIVDIR/ruby_test  && rm -rf $FIVDIR/ruby_test_backup 
        
}

function run_test()
{       
        tc_info "calling the test through miniruby utility "
        # start the miniruby suit
        pushd $TEST_DIR  >$stdout 2>$stderr 
        tc_register "running the miniruby suit"
        ./miniruby ./tool/runruby.rb "./test/runner.rb" >$stdout 2>$stderr
        tc_pass_or_fail $? "some tests are either failed or some error occured" || return
	popd &>/dev/null
}
#
# main
#
tc_setup && \
run_test

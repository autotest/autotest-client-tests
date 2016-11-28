#!/bin/bash
# vi: set ts=8 sw=8 autoindent noexpandtab:
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
#
# File :	kvm.sh
#
# Description:	Test kvm functionality.
#
# Author:	Suzuki K P <suzukikp@in.ibm.com> 
#
################################################################################

#cd $(dirname $0)
#LTPBIN=${LTPBIN%/shared}/qemu_kvm
source $LTPBIN/tc_utils.source

config_file=""

# Find a file $2 at path $1
# The path of the file is saved at the variable file_path
function find_file_path()
{
	file_path=""

	file_path=`find $1 -type f -name \*$2\* 2>/dev/null | head -n 1`
}
	
function find_config_file()
{
	kern_ver=`uname -r`
	# Try /proc/config.gz
	[ -e /proc/config.gz ] && tc_executes "gzip" && {
		tc_info "Using /prc/config.gz as the config source";
		gzip -c -d /proc/config.gz > $TCTMP/config &&
		config_file=$TCTMP/config && return
	}

	if [ -e /boot/config-$kern_ver ]; then
		cp /boot/config-$kern_ver $TCTMP/config
		tc_info "Using the kernel config @ /boot/config-$kern_ver"
		return;
	fi

	tc_info "Could not detect the kernel config file. Tried /proc/config.gz, /boot/config-$kern_ver"
}


function tc_local_setup ()
{
	find_config_file
}

function check_cpu_support()
{
	tc_register "Checking CPU Virtualization capability"

	# Check if the processor supports VT
	matches=`egrep -c '(vmx|svm)' /proc/cpuinfo`
	if [ $matches -eq 0 ];then
		tc_conf "Processor not supporting Virtualization"
		return 1
	fi
	tc_pass_or_fail 0
}

function test_kvm_kmod()
{
	tc_register "KVM Modules"

	# RCP: what about lib64?
	# Fishy we are interested in /lib/modules/ 
	module_path="/lib/modules/$kern_ver"
	module_files="kvm.ko kvm-amd.ko kvm-intel.ko"
	local rc=0

	tc_info "Looking for kvm-kmod files"

	if [ ! -d $module_path ]; then
		tc_info "Could not find the modules path /lib/modules/$kern_ver";
		return;
	fi

	for module in $module_files;
	do
		find_file_path $module_path $module
		# RCP: With bash the following construct is not needed. Can simply say:
		#	if [ "$file_path" ] ...
		# The quotes are needed so an empty $file_path resolves to an empty string
		# and not a missing operand to the test command (aka "[" command).
		#if [ x$file_path == "x" ] || [ ! -e $file_path ]; then
		if [ "$file_path" ] && [ ! -e $file_path ]; then
			tc_info "Could not find the required module $module"
			((rc++))
		else
			tc_info "$module found at $file_path"
		fi
	done
	found_kvm_modules=$rc
	tc_info "$rc essential modules were not found"
	tc_pass_or_fail $rc
}

function test_kernel_config()
{
	tc_register "Kernel Config"

	local rc=0
	config_y="CONFIG_PARAVIRT_GUEST CONFIG_KVM_CLOCK CONFIG_KVM_GUEST CONFIG_PARAVIRT CONFIG_PARAVIRT_CLOCK CONFIG_HAVE_KVM"
	config_n="CONFIG_KVM_TRACE CONFIG_PARAVIRT_DEBUG"
	config_kvm="CONFIG_KVM CONFIG_KVM_INTEL CONFIG_KVM_AMD"

#	If we have found the kvm_modules already, don't bother to check the configs.
#	Otherwise, the configs should be built-in.
	if [ $found_kvm_modules -ne 0 ];
	then
		tc_info "kvm modules were not found"
		tc_info "KVM features should be built-in"
		config_y="$config_y $config_kvm"
	fi 

	for option in $config_y; 
	do
		grep -q "^$option=y" $TCTMP/config
		if [ $? -ne 0 ]; 
		then
			tc_info "$option is not enabled (BAD)"
			((rc++))
		else
			tc_info "$option is built-in (OK)"
		fi	
	done
	
	for option in $config_n;
	do
		grep -q "^$option=" $TCTMP/config
		if [ $? -eq 0 ]; 
		then
			tc_info "$option shouldn't be enabled(BAD)"
			((rc++))
		fi
	done

	tc_pass_or_fail $rc "Total configuration mismatches : $rc"
}

function do_test_kvm_runtime()
{
	tc_register "KVM Runtime tests"
	
	[ $found_kvm_modules -eq 0 ] && {
	# Load the kvm modules if not loaded
		modprobe kvm;
		modprobe kvm-intel || modprobe kvm-amd
	# wait for the udev to create /dev/kvm file
		sleep 2
	}
	if [ -e /dev/kvm ];
	then
		ls -al /dev/kvm | ( 
		read perm junk usr grp maj minor junk;
		if [ $perm != "crw-rw----+" ];
		then
			echo "Wrong permissions for /dev/kvm : $perm ecpecting crw-rw----+" 2>&2;
		fi
		( [ $usr != "root" ] || [ $grp != "kvm" ]) && {
			echo "Wrong user/group for /dev/kvm : $usr,$grp" 1>&2;
		}
		[ $maj != "10," ] && {
			echo "Wrong major num for /dev/kvm : $maj (10)" 1>&2;
		}
		) 2>$stderr

		# RCP: I recently added a "tc_pass" funcion call you can use. Note that on a PASS
		# the string passed to tc_pass_or_fail is never printed out.

		tc_pass_or_fail 0 "Attributes for /dev/kvm doesn't match"
	else
		tc_fail "Could not find /dev/kvm file" "Check if the Virtualization is enabled in BIOS "
	fi
}
function test_kvm_qemu_files()
{
	QEMU_KVM_FILES="
	/usr/lib/udev/rules.d/80-kvm.rules
	/usr/bin/qemu-img
	/usr/share/qemu-kvm/bios.bin
	/usr/share/qemu-kvm/vgabios-cirrus.bin
	/usr/share/qemu-kvm/vgabios.bin
	/usr/share/qemu-kvm/keymaps/common
	/usr/share/qemu-kvm/keymaps/modifiers"
	
	tc_register "kvm qemu files"
	tc_exists $QEMU_KVM_FILES || tc_fail "Missing files" || return
	tc_pass
}
	
function test_kvm_runtime()
{
	# The remaining tests require the config file
	if [ ! -e $TCTMP/config ];
	then
		tc_info  "Remaining tests are broken, due to missing config file"
		tc_info	 "Please put the config file under /boot/config-$kern_ver"
		tc_info	 "and re-run the tests"
	else

	# Run-time tests require that, either we have the kvm built with the kernel
	# or we have the kvm modules out of the kernel tree

		#( test_kernel_config || [ $found_kvm_modules -eq 0 ]) && 
		#( [ $found_kvm_modules -eq 0 ]) && 
		do_test_kvm_runtime
	fi
}
	
tc_setup
check_cpu_support || exit

TST_TOTAL=3

test_kvm_kmod
test_kvm_qemu_files
test_kvm_runtime


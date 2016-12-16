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
### File :        nasm.sh                                                      ##
##
### Description: NASM is the Netwide Assembler, a free portable assembler for  ##
##
### Author:       Anitha M, amalloji@linux.vnet.ibm.com                        ##
###########################################################################################

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/nasm
source $LTPBIN/tc_utils.source
TESTS_DIR="${LTPBIN%/shared}/nasm/test"
required="nasm ndisasm"

function tc_local_setup()
{
    tc_root_or_break || return
    tc_exec_or_break "$required" 
}

function tc_local_cleanup()
{
    pushd $TESTS_DIR &>/dev/null
    rm -f a32offs.com a32offs.lst a32offs.o
    popd &>/dev/null
}

#Testing nasm functionality
function test01
{ 

   pushd $TESTS_DIR &>/dev/null
   #Assemble into an ELF object file
   tc_register "Assembling an ELF object file"
   nasm -f elf a32offs.asm && file a32offs.o|grep -q ELF >$stdout 2>$stderr
   tc_pass_or_fail $? "Assembling an ELF object file failed"

   #Assemble into a raw binary file
   tc_register "Assembling a raw binary file"
   nasm -f bin a32offs.asm -o a32offs.com && file a32offs.com|grep -q ISO >$stdout 2>$stderr
   tc_pass_or_fail $? "Assembling a raw binary file failed"

   #Produce a list file with hex codes output
   tc_register "Producing  a list file with hex codes output"
   nasm -f coff a32offs.asm -l a32offs.lst && file a32offs.lst|grep -q ASCII >$stdout 2>$stderr
   tc_pass_or_fail $? "Producing  a list file with hex codes output failed"

   #Assemble and Generate Dependencies
   tc_register "Generate Makefile Dependencies with every assembly session"
   nasm -f elf -o a32offs.o -MD a32offs.dep a32offs.asm && file a32offs.dep|grep -q ASCII >$stdout 2>$stderr
   tc_pass_or_fail $? "Generate Makefile Dependencies with every assembly session failed"

   #Send Errors to a file
   tc_register "Sending errors to file a32offs.err if any"
   nasm -Z a32offs.err -f obj a32offs.asm && ! grep -q error a32offs.err  >$stdout
   tc_pass_or_fail $? "Failed: Sending errors to file"
   
   popd &>/dev/null

}

#Testing ndisasm functionality
function test02
{
   pushd $TESTS_DIR &>/dev/null
   #Disassemble 32bit code
   tc_register "Disassemble 32 bit code"
   ndisasm -b 32 a32offs.asm >$stdout 2>$stderr
   tc_pass_or_fail $? "Disassemble 32 bit code failed"

   #Disassemble a binary file at 0x100
   tc_register "Disassemble a binary file"
   ndisasm -o100h a32offs.com >$stdout 2>$stderr
   tc_pass_or_fail $? "Disassemble a binary file failed"
   popd &>/dev/null
}

################################### main ###########################################
tc_setup
TST_TOTAL=7
test01
test02 

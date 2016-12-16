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
###########################################################################
# name of file	: Makefile						  #
# description	: makefile for e2fsprogs testcase			  #
###########################################################################

# all executables in this directory are considered testcases
#TARGETS=`find . -maxdepth 1 -perm +111 -type f`
TARGETS=e2fsprogs.sh
DIRS=d_loaddump \
	f_bad_local_jnl \
	f_baddir \
	f_baddotdir \
	f_badprimary \
	f_bitmaps \
	f_dirlink \
	f_end-bitmap \
	f_ext_journal \
	f_holedir \
	f_journal \
	f_okgroup \
	f_orphan \
	f_preen \
	f_reconnect \
	f_swapfs \
	f_zero_group \
	f_zero_super

#FILES=run_e2fsck test_config
#SETUP=defaults

all:

install:
	@for i in $(TARGETS) $(FILES) ; do cp -p $$i ../../bin/$$i || break ; done ;
#	@for j in $(DIRS) $(SETUP) ; do cp -a $$j ../../bin/$$j || break ; done

uninstall:
	@for i in $(TARGETS) $(FILES) ; do rm -f ../../bin/$$i ; done ;
#	@for j in $(DIRS) $(SETUP) ; do rm -rf ../../bin/$$j || break ; done

clean:
	@rm -f *~ *.log *.ok *.new .failed


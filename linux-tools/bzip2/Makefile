###########################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
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
## name of file	: Makefile						  #
## description	: make(1) description file for the bzip2/bunzip2 test.    #
############################################################################################

TARGETS="bzip2.sh"

all:

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done
	## Bug 64116 Fix Start
	#ln -f sample1.ref ../../bin/sample1.ref || break
	#ln -f sample2.ref ../../bin/sample2.ref || break
	#ln -f sample3.ref ../../bin/sample3.ref || break
	#ln -f sample1.bz2 ../../bin/sample1.bz2 || break
	#ln -f sample2.bz2 ../../bin/sample2.bz2 || break
	#ln -f sample3.bz2 ../../bin/sample3.bz2 || break
	## Fix End

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done
	## Bug 64116 Fix Start
	#rm -f ../../bin/sample1.ref
	#rm -f ../../bin/sample2.ref
	#rm -f ../../bin/sample3.ref
	#rm -f ../../bin/sample1.bz2
	#rm -f ../../bin/sample2.bz2
	#rm -f ../../bin/sample3.bz2
	## Fix End

clean:
	@rm -f *~

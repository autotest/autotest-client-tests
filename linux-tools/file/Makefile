############################################################################################
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
## description	: make(1) description file for file command		  #
############################################################################################

TARGETS="file.sh"

all:	file-test-cprog file-tests.tar file-tests.tgz file-test.xxx.gz

file-tests.tar:
	tar cf file-tests.tar *

file-tests.tgz:
	tar cf file-tests.tgz *

file-test.xxx.gz:
	cp file-test-cprog.c file-test.xxx
	gzip file-test.xxx

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done
	ln -f file-tests.tar ../../bin/
	ln -f file-tests.tgz ../../bin/
	ln -f file-test.xxx.gz ../../bin/

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done
	rm ../../bin/file-tests.tar
	rm ../../bin/file-tests.tgz
	rm ../../bin/file-test.xxx.gz

clean:
	@rm -f *~ file-test-cprog file-tests.tar file-tests.tgz file-test.xxx.gz

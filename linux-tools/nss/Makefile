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
## name of file  : Makefile                                                #
## description   : makefile for nss testcases                              #
############################################################################################

TARGETS=nss.sh nss-sysinit.sh
OBJDIR_NAME=$(shell basename nss/cmd/tests/*.OBJ)

all:

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done
	mkdir -p dist/$(OBJDIR_NAME)/bin
	for exe in $(shell find nss/cmd -type f -o -type l -executable) ; do \
		ln -s ../../../$$exe dist/${OBJDIR_NAME}/bin; \
	done
	mkdir -p dist/$(OBJDIR_NAME)/lib
	cp -rp nss/lib/* dist/$(OBJDIR_NAME)/lib/

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done
	rm -f dist/$(OBJDIR_NAME)/bin/*
	rm -f dist/$(OBJDIR_NAME)/lib/*
	rm -rf dist

clean:
	@rm -f *~

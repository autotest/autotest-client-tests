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
## description   : makefile for unzip testcase                             #
############################################################################################

tst_unzip_file.zip:
	./unzip_genfile.sh

all:	tst_unzip_file.zip

install:	tst_unzip_file.zip
	ln -f unzip.sh ../../bin/unzip.sh 
	ln -f tst_unzip_file.zip ../../bin/tst_unzip_file.zip
	ln -f expected_unzip ../../bin/expected_unzip

uninstall:
	rm -f ../../bin/unzip.sh
	rm -f ../../bin/tst_unzip_file.zip
	rm -f ../../bin/expected_unzip

clean:
	@rm -f tst_unzip_file.zip expected_unzip *~

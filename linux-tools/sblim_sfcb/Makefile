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
# name of file	: Makefile						  #
# description	: make(1) description file for slim-sfcb tests        	  #
###########################################################################

# all executables in this directory are considered testcases
TARGETS=sblim-sfcb-test.sh

all:   wbemcat6


#apply_patch: bug36137-OK-patch bug36137-stage-patch bug45039-enumerateclasses-patch bug53891-updated-expected-results-patch

#bug53891-updated-expected-results-patch: bug53891-updated-expected-results.diff
#	patch -p1 < $< && touch $@

#bug36137-OK-patch: bug36137-OK-files.diff
#	patch -p0 < $< && touch $@

# Note thaqt the patch to enumerateclasses was removed from this diff file
# and re-incorporated with changes into bug45039-enumerateclasses.diff.
#bug36137-stage-patch: bug36137-stage-files.diff
#	patch -p0 < $< && touch $@

#bug45039-enumerateclasses-patch: bug45039-enumerateclasses.diff
#	patch -p0 < $< && touch $@

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done ;

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done ;

clean:
#	test -e bug53891-updated-expected-results-patch && patch -RN -p1 < bug53891-updated-expected-results.diff && rm -f bug53891-updated-expected-results-patch  || true 
#	test -e bug36137-OK-patch && patch -RN -p0 < bug36137-OK-files.diff && rm -f bug36137-OK-patch || true
#	test -e bug36137-stage-patch && patch -RN -p0 < bug36137-stage-files.diff && rm -f bug36137-stage-patch || true
#	test -e bug45039-enumerateclasses-patch && patch -RN -p0 < bug45039-enumerateclasses.diff && rm -f bug45039-enumerateclasses-patch || true

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

TARGETS=openhpi2.sh openhpi-commands_test.sh

all:	temp_patch bug53348-patch bug55214-patch
	$(MAKE) -C openhpi2-conformancetest build-tests

temp_patch: temp_patch.diff
	patch -N -p0 < temp_patch.diff
	touch $@

bug53348-patch: bug53348-openhpi-test-fix.diff
	(test -e bug53348-patch || patch -N -p1 < bug53348-openhpi-test-fix.diff)
	touch $@

bug55214-patch: bug55214-saHpiAnnunciatorGet-test-3.diff
	(test -e bug55214-patch || patch -N -p1 < bug55214-saHpiAnnunciatorGet-test-3.diff )
	touch $@

clean_temp_patch:
	(test -e bug53348-patch && patch -NR -p1 < bug53348-openhpi-test-fix.diff && rm -rf bug53348-patch) || true
	(test -e bug55214-patch && patch -NR -p1 < bug55214-saHpiAnnunciatorGet-test-3.diff && rm -rf bug55214-patch) || true
	patch -NR -p0 < temp_patch.diff
	rm -rf temp_patch

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done

uninstall:
	@for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done

clean:	clean_temp_patch
	@rm -f *~
	$(MAKE) -C openhpi2-conformancetest clean


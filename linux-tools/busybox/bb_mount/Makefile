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
# name of file  : Makefile                                                #
# description   : make(1) description file for busybox tests              #
###########################################################################

# Since cannot be built in ia64 fakeroot, build it once and check into CVS.
# This file is architecture independent anyway.
#all:	bb_mount.img.gz

all:

# not built - see above
bb_mount.img.gz: Makefile
	rm -f bb_mount.img bb_mount.img.gz
	dd if=/dev/zero of=bb_mount.img count=1024
	rm -rf mnt
	mkdir mnt
	mke2fs -F bb_mount.img
	mount bb_mount.img mnt -o loop
	echo "filesystem successfully mounted" > mnt/status
	umount mnt
	rm -rf mnt
	gzip bb_mount.img

install:
	ln -f  bb_mount.img.gz ../../../bin/ || break

uninstall:
	rm -f ../../../bin/bb_mount.img.gz

clean:
	# See above. No longer built each time.
	# rm -f bb_mount.img.gz

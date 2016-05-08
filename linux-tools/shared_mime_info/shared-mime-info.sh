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
### File :       shared-mime-info.sh                                           ##
##
### Description: This testcase tests shared-mime-info package                  ##
##
### Author:      Sheetal Kamatar <sheetal.kamatar@in.ibm.com>                  ##
###########################################################################################

#cd $(dirname $0)
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source
TESTDIR="${LTPBIN%/shared}/shared_mime_info"
MIMEDIR="/usr/share/mime"
REQUIRED="update-mime-database update-desktop-database"

function tc_local_setup() 
{
	# Check Installation
	tc_exec_or_break $REQUIRED || return 
	tc_exist_or_break $MIMEDIR || return
}

function update_mimeDB()
{
	tc_register "Update MIME type to MIME Database"
	cat > $MIMEDIR/packages/imagefile.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
<mime-type type="image/imagefile">
<comment>JPEG image</comment>
<glob pattern="*.imagefile"/>
</mime-type>
</mime-info>  
EOF

	# Update mime database
	update-mime-database $MIMEDIR
	tc_pass_or_fail $? "update-mime-database command failed" || return
}

function verify_files()
{
	tc_register "Verify files in Database"
	# Check if this updates various files in the database
	[ -e $MIMEDIR/image/imagefile.xml 2>$stderr 1>$stdout ] && \
	grep imagefile $MIMEDIR/globs 2>$stderr 1>$stdout && \
	grep imagefile $MIMEDIR/types 2>$stderr 1>$stdout
	tc_pass_or_fail $? "imagefile.xml not created" || return
}

function build_mimeDB()
{ 
	tc_register "Add MIME type to MIME Database"
	cat > /usr/share/applications/imagefile.desktop <<-EOF
		[Desktop Entry]
		Name=Image Viewer
		TryExec=display
		Exec=display %f
		Type=Application
		Categories=Viewer;
		MimeType=image/imagefile;
	EOF

	# Build a cache database of the MIME types handled by desktop files
	update-desktop-database
	tc_pass_or_fail $? "update-desktop-database command failed" || return
}

#
# main
#
tc_setup
TST_TOTAL=3
update_mimeDB
verify_files
build_mimeDB

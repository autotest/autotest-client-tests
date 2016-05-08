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
## File:			unzip_genfile.sh
##
## Description:	This program will generate the zip file that will be used to
##
## Author:		Manoj Iyer manjo@mail.utexas.edu
###########################################################################################

function cleanup()
{
	rm -fr /tmp/tst_unzip.* &>/dev/null
}
trap cleanup 0

function failure()
{
	echo FAILED: $*
	exit 1
}

numdirs=3                     # number of directories to create
numfiles=3                    # number of file to create in each directory
top_dirname=tst_unzip.dir     # name of the base directory
dircnt=0                      # index into number of dirs created in loop
fcnt=0                        # index into number of files created in loop

cat /dev/null > expected_unzip
dirname=$top_dirname
while ((dircnt<numdirs)) ;  do
	dirname=$dirname/d.$dircnt
	mkdir -p $dirname  &>/dev/null || failure "can't mkdir -p $dirname"
	echo $dirname >> expected_unzip

	fcnt=0
	while ((fcnt<numfiles)) ;  do
		echo "$dirname/file.$fcnt-data" > $dirname/file.$fcnt || failure "can't create $dirname/file.$fcnt"
		echo $dirname/file.$fcnt >> expected_unzip
		((++fcnt))
	done
	((++dircnt))
done

# Create ZIP file.
zip -r tst_unzip_file.zip $top_dirname &>/dev/null

rm -fr $top_dirname # &>/dev/null

#!/bin/bash
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
# File :	gettext.sh
#
# Description:	Test gettext package
#
# Author:	Andrew Pham (apham@us.ibm.com)	
################################################################################
# all commands to be tested:

commands=" xgettext msgmerge msgfmt msgunfmt ngettext \
	   gettext msgcmp msgcomm " 

REQUIRED="grep ls cat diff touch mkdir"
# source the utility functions
#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/gettext
TESTDIR=${LTPBIN%/shared}/gettext_test
source $LTPBIN/tc_utils.source

TST_TOTAL=8

#As there is not LOCALE support in ppcnf arch, excluding                        
#testcase,(ngettext, gettextize, gettext), which uses locale                    
                                                                                
tc_get_os_arch                                                                 
                                                                                
[ $TC_OS_ARCH = ppcnf ] && {                                                   
        commands=" xgettext msgmerge msgfmt msgunfmt msgcmp msgcomm "           
        TST_TOTAL=6                                                             
        }                            

# Initialize output messages
ErrMsg="Failed: Not available."
ErrMsg1="Failed: Unexpected output.  Expected:"

################################################################################
# testcase functions
################################################################################
#
# Modify "make check" plural-1 test
#



# xgettext - Extract translatable strings from given input files

function TC_xgettext()
{
	cat > $TCTMP/myprog.c <<-EOF
	#ifdef HAVE_CONFIG_H
	# include <config.h>
	#endif

	#include <stdlib.h>
	#include <stdio.h>
	#include <locale.h>

	/* Make sure we use the included libintl, not the system's one. */
	#define textdomain textdomain__
	#define bindtextdomain bindtextdomain__
	#define ngettext ngettext__
	#undef _LIBINTL_H
	#include "libgnuintl.h"

	int main(int argc, char* argv[])
	{
		int n = atoi (argv[1]);

		if (setlocale (LC_ALL, "") == NULL)
			return 1;

		textdomain ("cake");
		bindtextdomain ("cake", ".");
		printf (ngettext ("a piece of cake", \
			"%d pieces of cake", n), n);
		printf ("\n");
		return 0;
	}
	EOF
	
	xgettext -o $TCTMP/cake.pot --omit-header $TCTMP/myprog.c \
	>/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$ErrMsg" || return 1

	grep -q "%d pieces of cake" $TCTMP/cake.pot &&
        grep -q "a piece of cake" $TCTMP/cake.pot
	tc_pass_or_fail $?  "got: `cat $TCTMP/cake.pot`" \
		|| return 1
	return 0
}



## msgmerge - Merges  two Uniforum style .po files together.  The def.po file is an existing PO file 
## 		with translations which will be taken over to the newly created file as long as they still match;
##		comments will be preserved, but extracted comments and file positions will be discarded.
##		The  ref.pot  file is  the  last  created  PO  file with up-to-date source references but old translations
##		, or a PO Template file (generally created by xgettext); any translations or comments in the file will be discarded,
##		however dot comments and file positions will be preserved.
function TC_msgmerge()
{
	cat > $TCTMP/fr_FR.po <<-EOF
	msgid "a piece of cake"
	msgid_plural "%d pieces of cake"
	msgstr[0] "un morceau de gateau"
	msgstr[1] "%d morceaux de gateau"
	EOF
	
	msgmerge -q -o $TCTMP/fr_FR.po.new $TCTMP/fr_FR.po $TCTMP/cake.pot \
		>/dev/null 2>>$stderr
	tc_fail_if_bad $?  "$ErrMsg" || return 1
	
	grep -q "un morceau de gateau" $TCTMP/fr_FR.po.new &&
        grep -q "%d morceaux de gateau" $TCTMP/fr_FR.po.new
	tc_pass_or_fail $?  "$ErrMsg1 `cat $TCTMP/fr_FR.po` got: `cat $TCTMP/fr_FR.po.new`" \
		|| return 1
	return 0
}


## msgfmt - Generate binary message catalog from textual translation description.
function TC_msgfmt()
{
	msgfmt -o $TCTMP/cake.mo $TCTMP/fr_FR.po >/dev/null 2>>$stderr
	tc_fail_if_bad $? "$ErrMsg" || return 1
		
	msgunfmt $TCTMP/cake.mo -o $TCTMP/fr_FR.po.tmp >/dev/null 2>>$stderr
	tc_fail_if_bad $? "$ErrMsg" || return 1
	
	diff $TCTMP/fr_FR.po $TCTMP/fr_FR.po.tmp >& /dev/null
	tc_pass_or_fail $?  "$ErrMsg1 `cat $TCTMP/fr_FR.po` got: `cat $TCTMP/fr_FR.po.tmp`" \
		|| return 1

	return 0
}


## msgcmp - Compare  two  Uniforum  style  .po files to check that both contain the same set of msgid strings.
##		The def.po file is an existing PO file with the translations.  The ref.pot file is the last
##		created PO file, or a PO Template file (generally created by xgettext). This is  useful  for  checking
##		that  you  have  translated each and every message in your program.
function TC_msgcmp()
{
	msgcmp $TCTMP/fr_FR.po  $TCTMP/fr_FR.po  >/dev/null 2>$stderr
	tc_fail_if_bad $? "$ErrMsg" || return 1
		
	echo "msgid \"red\"" >> $TCTMP/cake.pot
	echo 'msgstr "mau ddo"' >> $TCTMP/cake.pot

	msgcmp $TCTMP/fr_FR.po  $TCTMP/cake.pot >&/dev/null
	if [ $? -ne 0 ]; then
		tc_pass_or_fail 0 "$ErrMsg1" || return 0
	else
		tc_pass_or_fail 1 "$ErrMsg1" || return 1
	fi
}


## msgcomm- Find  messages  which  are  common to two or more of the specified PO files.
function TC_msgcomm()
{
	msgcomm -o $TCTMP/message.po $TCTMP/cake.pot  $TCTMP/fr_FR.po  \
	>/dev/null 2>$stderr
	tc_fail_if_bad $? "$ErrMsg" || return 1
		
	cat $TCTMP/message.po | grep cake >&/dev/null
	tc_pass_or_fail $? "$ErrMsg1" || return 1

	return 0
}


## msgunfmt - uncompile message catalog from binary format
function TC_msgunfmt()
	{
	tc_info "$TCNAME: See TC_msgfmt testcase."
	return 0
}


## ngettext - translate message and choose plural form
function TC_ngettext()
{	
	local RC=0
	
	My_Lang=$LANGUAGE
	My_all=$LC_ALL
	My_msg=$LC_MESSAGES
	My_La=$LANG

	LANGUAGE=
	LC_ALL=fr_FR
	LC_MESSAGES=
	LANG=
	export LANGUAGE LC_ALL LC_MESSAGES LANG
	
	[ -d /tmp/gettext ] || mkdir /tmp/gettext
	[ -d /tmp/gettext/fr_FR ] || mkdir /tmp/gettext/fr_FR
	[ -d /mp/gettext/fr_FR/LC_MESSAGES ] || mkdir /tmp/gettext/fr_FR/LC_MESSAGES
	cp $TCTMP/cake.mo /tmp/gettext/fr_FR/LC_MESSAGES/cake.mo
	cp $TCTMP/fr_FR.po /tmp/gettext/fr_FR/LC_MESSAGES/fr_FR.po

#	cd $LTPBIN
	$TESTDIR/test_gettext 2 | grep morceaux >&/dev/null
	tc_pass_or_fail $? "$ErrMsg" || RC=1
	
	LANGUAGE=$My_Lang
	LC_ALL=$My_all
	LC_MESSAGES=$My_msg
	LANG=$My_La
	export LANGUAGE LC_ALL LC_MESSAGES LANG
	
	return $RC
}


## gettext - translate message
function TC_gettext()
{	
	local RC=0

	My_Lang=$LANGUAGE
	My_all=$LC_ALL
	My_msg=$LC_MESSAGES
	My_La=$LANG

	LANGUAGE=
	LC_ALL=fr_FR
	LC_MESSAGES=
	LANG=
	export LANGUAGE LC_ALL LC_MESSAGES LANG
	
#	cd $LTPBIN
	$TESTDIR/test_gettext 2 | grep morceaux >&/dev/null
	tc_pass_or_fail $? "$ErrMsg" || RC=1
	
	LANGUAGE=$My_Lang
	LC_ALL=$My_all
	LC_MESSAGES=$My_msg
	LANG=$My_La
	export LANGUAGE LC_ALL LC_MESSAGES LANG
	
	rm -rf /tmp/gettext >&/dev/null
	return $RC
}

################################################################################
# main
################################################################################
tc_setup
tc_run_me_only_once

# Check if supporting utilities are available
tc_exec_or_break $REQUIRED || exit 
E_value=0
for cmd in $commands
do
	tc_register $cmd 
	TC_$cmd || E_value=1 
done
exit $E_value

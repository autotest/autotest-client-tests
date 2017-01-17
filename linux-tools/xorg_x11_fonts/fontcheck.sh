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
## File :	fontcheck.sh
##
## Description:	This testcase checks fonts in a font directory.
##
## Author:	Shoji Sugiyama (shoji@jp.ibm.com)
###########################################################################################
## source the standard utility functions

#cd `dirname $0`
#LTPBIN=${LTPBIN%/shared}/xorg_x11_fonts
source $LTPBIN/tc_utils.source
TEST_PATH=${LTPBIN%/shared}/xorg_x11_fonts
cp $TEST_PATH/xclient $LTPBIN
################################################################################
# Global variables
################################################################################

BASEFONTDIR=/usr/share/X11/fonts
FONT=""
CODESET=""
FONTDIR=""
CHK_ENC="no"
CHK_ALIAS="no"
CHK_FONTSET="no"
CHK_SCALABLE="no"
VERBOSE="no"
LOCMASK=""
KILLME=""
ARGS="$@"	# save incomming args

################################################################################
# any utility functions specific to this file can go here
################################################################################

function usage()
{
	tc_break_if_bad 1 \
	"usage $0 [ -a ] [ -e ] [ -s ] [ -t ] [ -v ] -f <font family> \\" \
	"		[ -d <fonts directory> ] [ -x <extra font path> \\" \
	"		[[ -l <locale mask> ] | [ -c codeset ]]" \
	"	-a requests check of fonts.alias file" \
	"	-e requests check of encodings.dir file" \
	"	-s requests check of scalable fonts" \
	"	-t requests check of create font set" \
	"	-v displays testing information" \
	"	example extra font path: misc (this is relative to <fonts directory>)" \
	"	example font family: 75dpi" \
	"	example (and default) fonts directory: $BASEFONTDIR" \
	"	example locale mask: ja" \
	"	example locale mask: \"^en_US\$\"" \
	"	example codeset: \"8859-2\"" \
	"	locale mask defaults to current locale's LANG value" \
	"Your command line was: $0 $ARGS"
	exit 1
}

function parse_args()
{
	[ $# == 0 ] && usage		# usage exits
	
	while getopts ac:d:ef:l:stvx: opt ; do
		case "$opt" in
			a)	CHK_ALIAS="yes"
				;;
			c)	CODESET="$OPTARG"
				;;
			d)	BASEFONTDIR="$OPTARG"
				;;
			e)	CHK_ENC="yes"
				;;
			f)	FONT="$OPTARG"
				;;
			l)	LOCMASK="$OPTARG"
				;;
			s)	CHK_SCALABLE="yes"
				;;
			t)	CHK_FONTSET="yes"
				;;
			v)	VERBOSE="yes"
				;;
			x)	XTRAPATH="$OPTARG"
				;;
			*)	usage
				;;
		esac
	done
	[ "$FONT" ] || usage		# usage exits

	FONTDIR=${BASEFONTDIR}/$FONT
	tc_info "testing fonts in $FONTDIR"
	[ "$XTRAPATH" ] && tc_info "and extra path $XTRAPATH"
	return 0
}

function fix-bug-15276-about-japanese-fonts()
{
	
	local TMP_FONT_FILE="$TCTMP/font.dir.tmp"

	# To fix bug 15276
	if [ "$FONT" != "japanese" ]; then
		return 1
	fi 

	CHK_ALIAS="no"

	if [ "$1" = "Fix-fonts-dir" ] ; then
		if [ -f "$FONTDIR/fonts.dir" ] ; then
			  mv $FONTDIR/fonts.dir $FONTDIR/fonts.dir.115
	  
			  grep -v jisx0213 $FONTDIR/fonts.dir.115 > $TMP_FONT_FILE

	  		  echo $(( $(wc -l < $TMP_FONT_FILE) - 1 )) > $FONTDIR/fonts.dir
	  		  tail -n $(( $(wc -l < $TMP_FONT_FILE) - 1 )) $TMP_FONT_FILE >> $FONTDIR/fonts.dir
		fi
	elif [ "$1" = "Recover-fonts-dir" ] ; then
	   	if [ -f "$FONTDIR/fonts.dir.115" ] ; then
	   		mv  $FONTDIR/fonts.dir{.115,} 
		fi
	else
		echo " Usage : fix-bug-15276-about-japanese-fonts \"Fix-fonts-dir\" or \"Recover-fonts-dir\" "
		return 1
	fi
}

function make_fontdir ()
{
	if $(ls $FONTDIR |grep -e 'pcf' -e 'snf' -e 'bdf' > /dev/null ); then
	    mkfontdir -e /usr/share/fonts/encodings/ -e /usr/share/fonts/encodings/large/ $FONTDIR &>/dev/null 
	else
	    mkfontscale -e /usr/share/fonts/encodings/ -e /usr/share/fonts/encodings/large/ $FONTDIR &>/dev/null
	fi
}

function tc_local_setup()
{
	tc_exec_or_break killall xset xlsfonts Xvfb mkfontscale mkfontdir|| return
	tc_exist_or_break ./xclient || return

        # start Xvfb when needs.
          ps -elf|grep "Xvfb :100.0 -screen 0 1024x768x24"|grep -v grep > /dev/null 2>&1
          if [ $? -ne 0 ] ; then
            Xvfb :100.0 -screen 0 1024x768x24 -fp /usr/share/fonts/misc &>$stdout & 
            KILLME=$!
	    tc_wait_for_pid $KILLME
	    tc_break_if_bad $? "Could not start Xvfb" || exit 1
	    sleep 5
          fi

          export DISPLAY=:100.0
          export LANG=POSIX

	# start an xclient with name unique to this instance
	xclient=`which xclient`
        my_xclient=xclient$$
        cp $xclient $TCTMP/$my_xclient
        eval $TCTMP/$my_xclient &

	parse_args $ARGS	# sets $FONTDIR
	
	make_fontdir

        fix-bug-15276-about-japanese-fonts Fix-fonts-dir

        if [ "$XTRAPATH" ] ; then
		xset fp "$FONTDIR/,${BASEFONTDIR}/$XTRAPATH/" &>/dev/null
	else
		xset fp "$FONTDIR" &>/dev/null
	fi

	xset fp rehash &>/dev/null
 
}

function tc_local_cleanup()
{
	xset fp &>/dev/null
	xset fp rehash &>/dev/null

	[ "$KILLME" ] && kill $KILLME
	[ "$my_xclient" ] &&
        killall "$my_xclient" &>/dev/null
 
        fix-bug-15276-about-japanese-fonts Recover-fonts-dir
 
}

################################################################################
# the testcase functions
################################################################################

#
# test01	installation check
#
function test01()
{
	tc_register	"are $FONT fonts installed?"
	tc_exist_or_break $FONTDIR && [ -d $FONTDIR ]
	tc_pass_or_fail $? "$FONT fonts not installed in $FONTDIR"
}

#
# test02	fonts.dir check
#
function test02()
{
	#
	# Register test case
	#
	tc_register "Checks font files in fonts.dir"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break cut egrep grep || return

	#
	# Prepare test files
	#
	tc_exist_or_break $FONTDIR/fonts.dir
	tc_fail_if_bad $? "$FONTDIR/fonts.dir does not exist" || return
	cut -d ' ' -f2- $FONTDIR/fonts.dir | grep -- "-" | cut -f 1 | grep -v -- "-0-0-0-0-c-" > $TCTMP/file1 2> /dev/null
	[ $VERBOSE == "yes" ] && cp $TCTMP/file1 /tmp/fontsdir.list

	#
	# Execute and check result
	#
	tc_info "running xlsfonts -lllo -fn \"<font name>\" for each $FONT font. This may take a minute."
	while read font
	do
		# echo $font
		strace -v -o log -f xlsfonts -lllo -fn "$font" 2>$stderr | grep -q 'character metrics:\|bounds:' >> $stderr
		tc_fail_if_bad $? "Failed to open font [$font]." || return
		[ $VERBOSE == "yes" ] && echo "Success to open [$font]"
	done < $TCTMP/file1
	tc_pass_or_fail 0 "PASSed if we get this far"
}

#
# test03	fonts.dir check
#
function test03()
{
	#
	# Register test case
	#
	tc_register "Checks number of fonts in fonts.dir"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break ls grep wc || return

	#
	# Ensure fonts.dir tc_exist_or_break
	#
	tc_exist_or_break $FONTDIR/fonts.dir
	tc_fail_if_bad $? "$FONTDIR/fonts.dir does not exist" || return

	#
	# Execute and check result
	#
	grep -v -- "-" $FONTDIR/fonts.dir | grep -v pcf >$stdout 2>>$stderr
	tc_fail_if_bad $? "bad $FONTDIR/fonts.dir" || return 
	declare -i num1=`cat $stdout`

	grep -- "-" $FONTDIR/fonts.dir | cut -d' ' -f1 > $TCTMP/file1
	declare -i num2=0
	while read file
	do
		# echo $FONTDIR/$file
		ls $FONTDIR/$file > /dev/null 2>&1
		tc_fail_if_bad $? "Failed to find font file [$file]" || return
		[ $VERBOSE == "yes" ] && echo "Success to find font file [$file]"
		let num2+=1
		true
	done < $TCTMP/file1

	[ "$num1" ] && [ "$num2" ] && [ $num1 -eq $num2 ]
	tc_fail_if_bad $? "Failed by different number of fonts in fonts.dir." \
			"Expected $num1 (from fonts.dir)"\
			"to equal $num2 (from pcf)" || return

	[ $num1 -gt 0 ]
	tc_pass_or_fail $? "No fonts found."

	[ $VERBOSE == "yes" ] && tc_info "Found $num1 $FONT fonts"
}

#
# test04	fonts.alias check
#
function test04()
{
	#
	# Register test case
	#
	tc_register "Checks font alias name in fonts.alias"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break cut grep || return

	#
	# Prepare test files
	#
	tc_exist_or_break $FONTDIR/fonts.alias
	tc_fail_if_bad $? "$FONTDIR/fonts.alias does not exist" || return

	grep ^\" $FONTDIR/fonts.alias > /dev/null 2>&1
	if [ $? == 0 ]
	then
		cut -d"\"" -f2 $FONTDIR/fonts.alias | sed '/^[[:space:]]*$/d' > $TCTMP/file1
	else
		grep -v "\!" $FONTDIR/fonts.alias | cut -d ' ' -f1 | cut -f1 | sed '/^[[:space:]]*$/d' > $TCTMP/file1
	fi	

	#
	# Execute and check result
	#
	while read font
	do
		# echo $font
		[ "$font" != "" ] && xlsfonts -lllo -fn "$font" 2> $stderr | grep -q "character metrics:" >> $stderr
		tc_fail_if_bad $? "Failed to open font [$font]" || return
		[ $VERBOSE == "yes" ] && echo "Success to open [$font]"
	done < $TCTMP/file1
	tc_pass_or_fail 0 "PASSed if we get this far"
}

#
# test05	encoding.dir check
#
function test05()
{
	#
	# Register test case
	#
	tc_register "Checks encoding.dir"

	tc_exist_or_break $FONTDIR/encodings.dir
	tc_fail_if_bad $? "missing $FONTDIR/encodings.dir" || return

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break ls grep cut || return

	#
	# Prepare test files
	#
	cut -d ' ' -f2 $FONTDIR/encodings.dir | grep enc > $TCTMP/file1

	#
	# Execute and check result
	#
	while read file
	do
		ls $file > /dev/null 2>&1
		tc_fail_if_bad $? "Failed to find encoding file [$file]" || return
		[ $VERBOSE == "yes" ] && echo "Success to find encoding file [$file]"
		true
	done < $TCTMP/file1
	tc_pass_or_fail 0 "PASSed if we get this far"
}

#
# test06	Scalable font check
#
function test06()
{
	#
	# Register test case
	#
	tc_register "Checks scalable fonts in fonts.dir"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break cut grep sed || return

	#
	# Prepare test files
	#
	tc_exist_or_break $FONTDIR/fonts.dir
	tc_fail_if_bad $? "$FONTDIR/fonts.dir does not exist" || return
	cut -d ' ' -f2- $FONTDIR/fonts.dir | grep -- "-" | cut -f 1 | grep -v -- "-c-" > $TCTMP/file1 2> /dev/null
	rm -f $TCTMP/file2
	for point in 10 32 43 64
	do
		grep -- "--0-0-0-0-" $TCTMP/file1 | sed "s/--0-0-0-0-/--$point-*-*-*-/" | sed "s/-0-/-*-/"  >> $TCTMP/file2
	done

	#
	# Execute and check result
	#
	while read font
	do
		# echo $font
		xlsfonts -lllo -fn "$font" 2> /dev/null | grep "character metrics:" > /dev/null 2>&1
		tc_fail_if_bad $? "Failed to open font [$font]." || return
		[ $VERBOSE == "yes" ] && echo "Success to open [$font]"
	done < $TCTMP/file2
	tc_pass_or_fail 0 "PASSed if we get this far"
}

#
# test07	Create FontSet
#
function test07()
{
	#
	# Register test case
	#
	tc_register "[xcrfs] create fontset"

	#
	# Check if prereq commands are existed.
	#
	tc_exec_or_break locale echo grep cut || return

	#
	# Prepare test files
	#
	cut -d' ' -f2- $FONTDIR/fonts.dir | grep -v "fontspecific" | cut -d '-' -f1-8 | grep -- ^- | sort | uniq | sed 's/$/-*-*-*-*-*-*-*/' > $TCTMP/file1
	# [ -f $FONTDIR/fonts.alias ] && \
	# cut -d' ' -f 1 $FONTDIR/fonts.alias | grep -- "-" | cut -f 1 | cut -d '-' -f1-12 | grep -- ^- | sed 's/$/-*/' >> $TCTMP/file1

	if [ -f $FONTDIR/fonts.alias ] 
	then
		grep ^\" $FONTDIR/fonts.alias > /dev/null 2>&1
		if [ $? == 0 ]
		then
			cut -d"\"" -f2 $FONTDIR/fonts.alias | grep -- "-" | cut -d '-' -f1-12 | grep -- ^- | sed 's/$/-*/' >> $TCTMP/file1
		else
			cut -d' ' -f 1 $FONTDIR/fonts.alias | grep -- "-" | cut -f 1 | cut -d '-' -f1-12 | grep -- ^- | sed 's/$/-*/' >> $TCTMP/file1
		fi	
	fi

	[ -s $TCTMP/file1 ]
	tc_fail_if_bad $? "No fonts found for $FONTDIR" || return

	#
	# Use current locale if none specified
	#
	rm -f $TCTMP/file2
	if [ "$CODESET" != "" ]
	then
		for loc in `locale -a`
		do
	 		cmap=`LANG=$loc locale charmap`
		 	echo $cmap | grep -qi "$CODESET" && echo $loc > $TCTMP/file2
		done
	else
		LOC_LANG=`locale | grep "^LANG="`
		LOC_LANG=${LOC_LANG/LANG=/}
        	[ "$LOCMASK" ] || LOCMASK="^$LOC_LANG\$"
		locale -a | grep "$LOCMASK" > $TCTMP/file2
		cat $TCTMP/file2 |grep -v jisx0213  > $TCTMP/file3
		mv $TCTMP/file3 $TCTMP/file2
	fi	
	[ -s $TCTMP/file2 ]
	tc_fail_if_bad $? "No locale found matching \"$LOCMASK\" or \"$CODESET\"" || return

	#
	# Execute and check result
	#
	# for loc in `locale -a | grep "$LOCMASK"`
	for loc in `cat $TCTMP/file2`
	do
	    xcrfs -lang $loc -fs "*" > /dev/null 2>&1
	    if [ $? -gt 100 ]
	    then
	    	tc_info "X locale [$loc] is not supported. Skip it."
		continue
	    fi
	    tc_info "Processing locale [$loc]"
	    while read font
	    do
		# echo $font
		xcrfs -lang $loc -fs "$font" >$stdout 2>$stderr
		mc=$?
		if [ $mc -gt 200 ] ; then
			tc_pass_or_fail $mc \
			"failed to create fontset [$loc] [$font]."
			return
		fi
		if [ $mc -gt 100 ] ; then
			tc_pass_or_fail $mc \
			"failed to connect X server or xlocale [$loc]."
			return
		fi
		if [ $mc -gt 0 ] ; then
			tc_info "(info only) $mc missing files for [$loc] [$font]."
		fi
		[ $VERBOSE == "yes" ] && \
			tc_info "Success for [$loc] [$font]."
	    done < $TCTMP/file1
	done	
	tc_pass_or_fail 0 "PASSed if we get this far"
}

################################################################################
# main
################################################################################

TST_TOTAL=3

# standard tc_setup
tc_setup
tc_run_me_only_once

test01 || exit
test02
test03
[ $CHK_ALIAS = "yes" ] && let TST_TOTAL+=1 && test04
[ $CHK_ENC == "yes" ] && let TST_TOTAL+=1 && test05
[ $CHK_SCALABLE == "yes" ] && let TST_TOTAL+=1 && test06
[ $CHK_FONTSET == "yes" ] && let TST_TOTAL+=1 && test07

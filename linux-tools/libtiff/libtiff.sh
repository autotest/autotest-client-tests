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
## File :	tiff.sh
##
## Description:	Test tiff package
##
## Author:	Andrew Pham, apham@austin.ibm.com
###########################################################################################
## source the utility functions

#cd `dirname $0`
#LTPBIN=${PWD%%/testcases/*}/testcases/bin
source $LTPBIN/tc_utils.source

picdir=${LTPBIN%/shared}/libtiff/pic

TST_TOTAL=21
REQUIRED="cp grep"

COMMANDS="fax2ps fax2tiff gif2tiff pal2rgb ppm2tiff ras2tiff raw2tiff \
          rgb2ycbcr thumbnail tiff2bw tiff2pdf tiff2ps tiff2rgba tiffcmp \
          tiffcp tiffdither tiffdump tiffinfo tiffmedian tiffset tiffsplit \
	  bmp2tiff"
	  # 17 20 26

################################################################################

function Notest()
{
	tc_info "$1 Not tested"
}	

################################################################################
# testcase functions
################################################################################
function TC_bmp2tiff()
{
	tc_register "bmp2tiff"
	bmp2tiff $picdir/test.bmp $TCTMP/test.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/test.tif >$stdout 2>$stderr
	grep -q "Image Width: 320" $stdout &&
	grep -q "Bits/Sample: 8" $stdout &&
	grep -q "Compression Scheme: PackBits" $stdout
	tc_pass_or_fail $? "Unexpected output."
}

function TC_gif2tiff()
{
	tc_register "gif2tiff"
	gif2tiff $picdir/test.gif $TCTMP/t.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/t.tif >$stdout 2>$stderr
	grep -q "Image Width: 320" $stdout &&
	grep -q "Planar Configuration: single image plane" $stdout &&
	grep -q "Compression Scheme: PackBits" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_tiffinfo()            
{
	tc_register "tiffinfo"
	tiffinfo $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "Image Width: 320" $stdout &&
	grep -q "Planar Configuration: single image plane" $stdout &&
	grep -q "Compression Scheme: PackBits" $stdout 
	tc_pass_or_fail $? "Unexpected output." || return
	
	tc_register "tiffinfo -c"
	let TST_TOTAL+=1
	tiffinfo -c $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "Color Map" $stdout &&
	grep -q "10663 10663" $stdout &&
	grep -q "Compression Scheme: PackBits" $stdout 
	tc_pass_or_fail $? "Unexpected output."
	
	tc_register "tiffinfo -s"
	let TST_TOTAL+=1
	tiffinfo -s $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "8 Strips" $stdout &&
	grep -q 9639 $stdout &&
	grep -q "Compression Scheme: PackBits" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_tiffdump()            
{
	tc_register "tiffdump"
	tiffdump  $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return


	grep -q "<little-endian>" $stdout &&
	grep -q "Orientation (274) SHORT (3) 1<1>" $stdout &&
	grep -q Colormap $stdout 
	tc_pass_or_fail $? "Unexpected output." || return

	tc_register "tiffdump -h"
	let TST_TOTAL+=1
	tiffdump  -h $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "(4) 8<0x170" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_fax2ps()            
{
	tc_register "fax2ps"
	fax2ps $picdir/fax.tif  >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "Creator: fax2ps" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_fax2tiff()            
{
	tc_register "fax2tiff -1 -p -M -R"
	fax2tiff -o $TCTMP/f.tif -1 -p -M -R 98 $picdir/fax.g3 \
		>$stdout 2>/dev/null
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/f.tif > $stdout
	grep -q CCITT $stdout &&
	grep -q fax $stdout
	tc_pass_or_fail $? "Unexpected output."
}

function TC_pal2rgb()            
{
	tc_register "pal2rgb"
	pal2rgb $picdir/pal.tif $TCTMP/p.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/p.tif | grep -q Deflate 
	tc_pass_or_fail $? "Unexpected output."

	tc_register "pal2rgb -pr"
	let TST_TOTAL+=1
	pal2rgb -r 8 -p contig $picdir/pal.tif  $TCTMP/p2.tif >$stdout \
		2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/p2.tif | grep "Rows/Strip" | grep -q 8 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_ppm2tiff()            
{
	Notest ppm2tiff
}

function TC_ras2tiff()            
{
	Notest ras2tiff
}

function TC_rgb2ycbcr()            
{
	tc_register "rgb2ycbcr"
	rgb2ycbcr $picdir/os.tif $TCTMP/ycb.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/ycb.tif >$stdout 2>$stderr
	grep -q YCbCr $stdout &&
	grep -q 0.299 $stdout &&
	grep -q 256 $stdout 
	tc_pass_or_fail $? "Unexpected output."

	tc_register "rgb2ycbcr -cr"
	let TST_TOTAL+=1
	rgb2ycbcr -c none -r 8 $picdir/os.tif $TCTMP/ycb2.tif \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return
	
	tiffinfo $TCTMP/ycb2.tif >$stdout
	grep -q 8 $stdout &&
	grep -q None $stdout
	tc_pass_or_fail $? "Unexpected output."
}


function TC_thumbnail()            
{
        Notest thumbnail
}


function TC_tiff2bw()            
{
	tc_register "tiff2bw"
	tiff2bw $picdir/os.tif $TCTMP/bw.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/bw.tif >$stdout 2>$stderr
	grep -q "os.tif" $stdout &&
	grep -q "min-is-black" $stdout &&
	grep -q "Compression Scheme: None" $stdout
	tc_pass_or_fail $? "Unexpected output." || return
	
	tc_register "tiff2bw -c"
	let TST_TOTAL+=1
	tiff2bw -c zip $picdir/os.tif $TCTMP/bw2.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/bw2.tif >$stdout 2>$stderr
	grep -q "os.tif" $stdout &&
	grep -q "min-is-black" $stdout &&
	grep -q "Deflate" $stdout
	tc_pass_or_fail $? "Unexpected output."
}


function TC_tiff2ps()            
{
	tc_register "tiff2ps"
	tiff2ps $picdir/x.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	grep -q "Creator: tiff2ps" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_tiff2rgba()            
{
	tc_register "tiff2rgba"
	tiff2rgba $picdir/os.tif $TCTMP/rgba.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/rgba.tif >$stdout 2>$stderr
	grep -q "PackBits" $stdout && 
	grep -q "1<assoc-alpha>" $stdout
	tc_pass_or_fail $? "Unexpected output." || return
	
	tc_register "tiff2rgba -nc"
	let TC_TOTAL+=1
	tiff2rgba -n -c zip $picdir/os.tif $TCTMP/rgba.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/rgba.tif >$stdout 2>$stderr
	grep -q "1<assoc-alpha>" $stdout
	[ $? -ne 0 ] &&
	grep -q "Deflate" $stdout  
	tc_pass_or_fail $? "Unexpected output."
}


function TC_tiffcmp()            
{
	tc_register "tiffcmp"
	tiffcmp $picdir/x.tif $picdir/x.tif >$stdout 2>$stderr
	tc_pass_or_fail $? "Not function correctly." || return

	tc_register "tiffcmp2"
	let TC_TOTAL+=1
	tiffcmp $picdir/x.tif $picdir/y.tif >$stdout 2>$stderr
	[ $? -ne 0 ]
	tc_pass_or_fail $? "Not function correctly." || return
}


function TC_tiffcp()            
{
	tc_register "tiffcp"
	tiffcp $picdir/x.tif $picdir/x2.tif $TCTMP/z.tif \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code." || return

	tiffinfo $TCTMP/z.tif > $TCTMP/tiffcp.res 2>/dev/null
	grep -q PackBits $TCTMP/tiffcp.res &&
	grep -q Deflate $TCTMP/tiffcp.res &&
	grep -q "single image plane" $TCTMP/tiffcp.res 
	tc_pass_or_fail $? "Unexpected output." || return

	tc_register "tiffcp -p"
	let TC_TOTAL+=1
	tiffcp -p separate $picdir/w.tif $picdir/w2.tif $TCTMP/z.tif \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code." || return

	tiffinfo $TCTMP/z.tif > $TCTMP/tiffcp2.res 2>/dev/null
	grep  -q PackBits $TCTMP/tiffcp2.res &&
	grep  -q Deflate $TCTMP/tiffcp2.res &&
	grep  -q "separate image plane" $TCTMP/tiffcp2.res 
	tc_pass_or_fail $? "Unexpected output."

	tc_register "tiffcp -r"
	let TC_TOTAL+=1
	tiffcp -r 20 $picdir/x.tif $picdir/x2.tif $TCTMP/z.tif \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code." || return

	tiffinfo $TCTMP/z.tif > $TCTMP/tiffcp.res3 2>/dev/null
	grep -q PackBits $TCTMP/tiffcp.res3 &&
	grep -q Deflate $TCTMP/tiffcp.res3 &&
	grep -q "Rows/Strip: 20" $TCTMP/tiffcp.res3 
	tc_pass_or_fail $? "Unexpected output."

	tc_register "tiffcp -t"
	let TC_TOTAL+=1
	tiffcp -t $picdir/x.tif $picdir/x2.tif $TCTMP/z.tif \
		>$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code." || return

	tiffinfo $TCTMP/z.tif > $TCTMP/tiffcp.res3 2>/dev/null
	grep -q "Rows/Strip: 25" $TCTMP/tiffcp.res3 
	[ $? -ne 0 ] &&
	grep -q PackBits $TCTMP/tiffcp.res3 &&
	grep -q Deflate $TCTMP/tiffcp.res3 
	tc_pass_or_fail $? "Unexpected output."
}


function TC_tiffdither()            
{
	tc_register "tiffdither"
	tiffdither $picdir/xb.tif $TCTMP/dither.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return
        
        tiffinfo $TCTMP/dither.tif >$stdout 2>$stderr
	grep  -q "Dithered B&W version of" $stdout &&
	grep  -q "min-is-black" $stdout
	tc_pass_or_fail $? "Unexpected output." || return

	tc_register "tiffdither -c"
	let TC_TOTAL+=1
	tiffdither -c zip $picdir/xb.tif $TCTMP/dither2.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

        tiffinfo $TCTMP/dither2.tif >$stdout 2>$stderr
	grep -q "Dithered B&W version of" $stdout &&
	grep -q "Deflate" $stdout &&
	grep -q "min-is-black" $stdout
	tc_pass_or_fail $? "Unexpected output."

	tc_register "tiffdither -f"
	let TC_TOTAL+=1
	tiffdither -f lsb2msb $picdir/xb.tif $TCTMP/dither3.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

        tiffinfo $TCTMP/dither3.tif >$stdout 2>$stderr
	grep -q "Dithered B&W version of" $stdout &&
	grep -q "lsb-to-msb" $stdout 
	tc_pass_or_fail $? "Unexpected output."
}

function TC_tiffmedian()            
{
	tc_register "tiffmedian"
	tiffmedian $picdir/os.tif $TCTMP/med.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/med.tif | grep -q palette 
	tc_pass_or_fail $? "Unexpected output."

	tc_register "tiffmedian -fc"
	let TC_TOTAL+=1
	tiffmedian -f -c packbits $picdir/os.tif $TCTMP/med2.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code" || return

	tiffinfo $TCTMP/med2.tif | grep -q PackBits 
	tc_pass_or_fail $? "Unexpected output."
}


function TC_tiffset()            
{
	tc_register "tiffset"
        cp $picdir/os.tif $TCTMP/tiffset.tif >$stdout 2>$stderr
        tiffset -s 270 "set by tiffset" $TCTMP/tiffset.tif
        tc_fail_if_bad $? "Incorrect return code" || return

        tiffinfo $TCTMP/tiffset.tif >$stdout 2>$stderr
        grep -q "set by tiffset" $TCTMP/tiffset.tif
        tc_pass_or_fail $? "Unexpected output."
}


function TC_tiffsplit()            
{
	tc_register "tiffsplit"
	tiffsplit  $TCTMP/z.tif >$stdout 2>$stderr
	tc_fail_if_bad $? "Incorrect return code." || return

	[ -e xaaa.tif -a -e xaab.tif ]  
	tc_pass_or_fail $? "Unexpected output."

	rm xaaa.tif xaab.tif # remove it
}


function TC_tiff2pdf()
{
	tc_register "tiff2pdf"
        tiff2pdf $picdir/x.tif >$stdout 2>$stderr
        tc_fail_if_bad $? "Incorrect return code" || return

        grep -q "Height 200" $stdout
        tc_pass_or_fail $? "Unexpected output."
}


function TC_raw2tiff()
{
        Notest raw2tiff
}


################################################################################
# main
################################################################################
tc_setup

# Check if supporting utilities are available
tc_exec_or_break  $REQUIRED || exit

FRC=0
for cmd in $COMMANDS
do
	TC_$cmd || FRC=$?
done
exit $FRC

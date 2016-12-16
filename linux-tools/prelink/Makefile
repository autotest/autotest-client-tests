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
## name of file	: Makefile						  #
## description	: makefile for prelink testcase				  #
############################################################################################

EXE = reloc1lib1.so reloc1lib2.so reloc1 cycle1 \
      cycle1lib1.so cycle1lib2.so layout1 \
      shuffle1lib1.so shuffle1lib2.so shuffle1
LIBS = layout1lib*.so
CFLAGS = -shared -O2 -fpic
TARGETS="prelink.sh"

all: $(EXE)

reloc1lib1.so: 
	$(CC) $(CFLAGS) -o reloc1lib1.so reloc1lib1.c

reloc1lib2.so:
	$(CC) $(CFLAGS) -o reloc1lib2.so reloc1lib2.c reloc1lib1.so

reloc1:
	$(CC) -O2 -fpic -o reloc1 reloc1.c -Wl,--rpath-link,. reloc1lib2.so reloc1lib1.so

cycle1lib1.so::
	echo 'int foo;' | $(CC) $(CFLAGS) -o cycle1lib1.so -xc -

cycle1lib2.so:
	echo 'int bar;' | $(CC) $(CFLAGS) -o cycle1lib2.so -xc - -xnone cycle1lib1.so

cycle1lib1.so:: cycle1lib2.so
	echo 'int foo;' | $(CC) $(CFLAGS) -o cycle1lib1.so -xc - -xnone cycle1lib2.so

cycle1: cycle1lib1.so cycle1lib1.so
	echo 'int main (void) { return 0; } ' | $(CC) -o cycle1 -xc - -xnone -Wl,--rpath-link,. cycle1lib2.so

layout1:
	for (( i=1; i <= 30; i++ )); \
	do \
	$(CXX) -shared -fpic -o layout1lib$$i.so layoutlib.C ; \
	done;
	$(CXX) -o layout1 layout.C layout1lib*.so ;

shuffle1lib1.so:
	$(CC) $(CFLAGS) -o shuffle1lib1.so reloc1lib1.c

shuffle1lib2.so:
	$(CC) $(CFLAGS) -o shuffle1lib2.so reloc1lib2.c shuffle1lib1.so
	
shuffle1::
	$(CC) -o shuffle1 reloc1.c -Wl,--rpath-link,. shuffle1lib2.so -Wl,--verbose 2>&1 | sed -e \
	'/^=========/,/^=========/!d;/^=========/d' \
	-e 's/0x08048000/0x08000000/;s/SIZEOF_HEADERS.*$$/& . += 56;/' > shuffle1.lds

shuffle1::
	$(CC) -o shuffle1 reloc1.c -Wl,--rpath-link,. shuffle1lib2.so shuffle1lib1.so -Wl,-T,shuffle1.lds

clean:
	@rm -f $(EXE)
	@rm -f $(LIBS)

install:
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done

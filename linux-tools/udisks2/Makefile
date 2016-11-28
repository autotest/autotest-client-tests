#  (C) Copyright IBM Corp. 2012
#
#  This program is free software;  you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY;  without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
#  the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program;  if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

###########################################################################
# name of file  : Makefile                                                #
# description   : makefile for udisks testcase                            #
###########################################################################
TARGETS=udisks.sh

all:

install:
	#patch -p0 <mcpbug84996-fix-multiple-test-issues.diff
	for i in $(TARGETS) ; do ln -f $$i ../../bin/$$i || break ; done

uninstall:
	for j in $(TARGETS) ; do rm -f ../../bin/$$j ; done
	#patch -p0 -R <mcpbug84996-fix-multiple-test-issues.diff

clean:
	@rm -f *~


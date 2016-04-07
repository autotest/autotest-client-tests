#
# Copyright (c) 2001-2002 Silicon Graphics, Inc.  All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

TOPDIR = ..
include $(TOPDIR)/include/builddefs

TESTS = $(wildcard *.test)
ROOT = $(wildcard root/*.test)
NFS = $(wildcard nfs/*.test)
LSRCFILES = sort-getfacl-output run make-tree $(TESTS) $(ROOT) $(NFS) \
	malformed-restore-double-owner.acl

include $(BUILDRULES)

default install install-dev install-lib:

PATH := $(abspath ../getfacl/):$(abspath ../setfacl/):$(abspath ../chacl/):$(PATH)

tests: $(TESTS)
root-tests: $(ROOT)
nfs-tests: $(NFS)

$(TESTS):
	@echo "*** $@ ***"; perl run $@

$(NFS):
	@echo "NFS specific tests"; echo "*** $@ ***"; perl run $@

$(ROOT):
	@echo "Note: Tests must run as root"; echo "*** $@ ***"; perl run $@

.PHONY: $(TESTS) $(NFS) $(ROOT)
.NOTPARALLEL:



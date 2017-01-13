#
# Copyright (c) 2004, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307 USA.
#
# Authors:
#       Mi,Jun  <jun.mi@intel.com>

TIMEOUT_CMD = ../t0

top_builddir = .

LOGFILE = $(top_builddir)/build_log

LDFLAGS := $(shell cat LDFLAGS | grep -v \^\#)

BUILD_TESTS := $(shell $(top_builddir)/find-test \
               --buildable $(top_builddir))

VERBOSE = 0

all: build-tests

build-tests: clean $(TIMEOUT_CMD) $(BUILD_TESTS:.c=.test)

tests-pretty:
	$(MAKE) all | column -t -s:

CFLAGS = -g -W -Wall -D__HPI_B_TEST__ 

INCLUDE = -Iinclude -I../include 


clean:
	@rm -f $(TIMEOUT_CMD)
	@rm -f $(LOGFILE)
	@find $(top_builddir) -iname \*.test | xargs -n 40 rm -f {}
	@find $(top_builddir) -iname \*~ -o -iname \*.o | xargs -n 40 rm -f {}

.PRECIOUS: %.test
%.test: %.o
	@COMPLOG=$(LOGFILE).$$$$; \
	[ -f $< ] || exit 0; \
	nm -g --defined-only $< | grep -q " T main" || exit 0; \
	if $(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) > $$COMPLOG 2>&1; \
	then \
		echo "$(@:.test=): link: PASS" | tee -a $(LOGFILE); \
	else \
		( \
			echo "$(@:.test=): link: FAILED. Linker output: "; \
			cat $$COMPLOG; \
		) >> $(LOGFILE); \
		echo "$(@:.test=): link: FAILED "; \
		if [ $(VERBOSE) -eq 1 ]; \
		then \
			cat $$COMPLOG; \
		fi; \
	fi; \
	rm -f $$COMPLOG;

.PRECIOUS: %.o
%.o: %.c
	@COMPLOG=$(LOGFILE).$$$$; \
	if $(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@ $(LDFLAGS) > $$COMPLOG 2>&1; \
	then \
		echo "$(@:.o=): build: PASS" | tee -a $(LOGFILE); \
	else \
		( \
			echo "$(@:.o=): build: FAILED: Compiler output: "; \
			cat $$COMPLOG; \
		) >> $(LOGFILE); \
		echo "$(@:.o=): build: FAILED "; \
		if [ $(VERBOSE) -eq 1 ]; \
		then \
			cat $$COMPLOG; \
		fi; \
	fi; \
	rm -f $$COMPLOG;

$(TIMEOUT_CMD):$(TIMEOUT_CMD).c
	@echo Building timeout helper files; \
	$(CC) -O2 -o $@ $< ; \



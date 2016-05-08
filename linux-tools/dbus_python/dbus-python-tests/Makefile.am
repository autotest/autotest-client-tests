abs_top_srcdir = @abs_top_srcdir@
abs_top_builddir = @abs_top_builddir@

EXTRA_DIST = \
	     cross-test-client.py \
	     cross-test-server.py \
	     crosstest.py \
	     run-test.sh \
	     run-with-tmp-session-bus.sh \
	     test-client.py \
	     test-p2p.py \
	     test-service.py \
	     test-signals.py \
	     test-standalone.py \
	     test-unusable-main-loop.py \
	     TestSuitePythonService.service.in \
	     tmp-session-bus.conf.in

# If you try to make this noinst, libtool helpfully gives us a static
# library, which doesn't work as a Python extension: so force the install
# target not to work here instead.
pyexec_LTLIBRARIES = dbus_py_test.la

install:
	@echo "Not installing anything from test/"

dbus_py_test_la_CPPFLAGS = -I$(top_srcdir)/include $(DBUS_CFLAGS) \
			   $(PYTHON_INCLUDES)
dbus_py_test_la_LDFLAGS = -module -avoid-version \
			  $(DBUS_LIBS)
dbus_py_test_la_SOURCES = dbus_py_test.c \
			  $(top_srcdir)/include/dbus-python.h

TESTS_ENVIRONMENT = DBUS_TOP_SRCDIR="$(abs_top_srcdir)" \
		    DBUS_TOP_BUILDDIR="$(abs_top_builddir)" \
		    DBUS_PYTHON_VERSION='$(PACKAGE_VERSION)' \
		    PYTHONPATH="$(abs_top_builddir)/test/.libs:$(abs_top_srcdir):$(abs_top_srcdir)/test:$(abs_top_builddir)/_dbus_bindings/.libs:$(abs_top_builddir)/_dbus_glib_bindings/.libs" \
		    PYTHON='$(PYTHON)'

TESTS = run-test.sh test-import-repeatedly

check_PROGRAMS = test-import-repeatedly

test_import_repeatedly_SOURCES = import-repeatedly.c
test_import_repeatedly_CPPFLAGS = $(PYTHON_INCLUDES)
test_import_repeatedly_LDFLAGS = $(PYTHON_LIBS)

cross-test-server:
	$(TESTS_ENVIRONMENT) $(PYTHON) $(top_srcdir)/test/cross-test-server.py
cross-test-client:
	$(TESTS_ENVIRONMENT) $(PYTHON) $(top_srcdir)/test/cross-test-client.py

.PHONY: cross-test-compile cross-test-server cross-test-client

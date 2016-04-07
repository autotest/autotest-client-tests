#! /bin/bash

# Copyright (C) 2006 Red Hat Inc. <http://www.redhat.com/>
# Copyright (C) 2006-2007 Collabora Ltd. <http://www.collabora.co.uk/>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

export DBUS_FATAL_WARNINGS=1
ulimit -c unlimited

function die() 
{
    if ! test -z "$DBUS_SESSION_BUS_PID" ; then
        echo "killing message bus $DBUS_SESSION_BUS_PID" >&2
        kill -9 "$DBUS_SESSION_BUS_PID"
    fi
    echo "$SCRIPTNAME: $*" >&2
    exit 1
}

if test -z "$PYTHON"; then
    echo "Warning: \$PYTHON not set, assuming 'python'" >&2
    export PYTHON=python
fi

if test -z "$DBUS_TOP_SRCDIR" ; then
    die "Must set DBUS_TOP_SRCDIR"
fi

if test -z "$DBUS_TOP_BUILDDIR" ; then
    die "Must set DBUS_TOP_BUILDDIR"
fi

SCRIPTNAME=$0

## so the tests can complain if you fail to use the script to launch them
export DBUS_TEST_PYTHON_RUN_TEST_SCRIPT=1
# Rerun ourselves with tmp session bus if we're not already
if test -z "$DBUS_TEST_PYTHON_IN_RUN_TEST"; then
  DBUS_TEST_PYTHON_IN_RUN_TEST=1
  export DBUS_TEST_PYTHON_IN_RUN_TEST
  exec "$DBUS_TOP_SRCDIR"/test/run-with-tmp-session-bus.sh $SCRIPTNAME
fi  

dbus-monitor > "$DBUS_TOP_BUILDDIR"/test/monitor.log &

echo "DBUS_TOP_SRCDIR=$DBUS_TOP_SRCDIR"
echo "DBUS_TOP_BUILDDIR=$DBUS_TOP_BUILDDIR"
echo "PYTHONPATH=$PYTHONPATH"
echo "PYTHON=$PYTHON"

echo "running test-standalone.py"
$PYTHON "$DBUS_TOP_SRCDIR"/test/test-standalone.py || die "test-standalone.py failed"

echo "running test-unusable-main-loop.py"
$PYTHON "$DBUS_TOP_SRCDIR"/test/test-unusable-main-loop.py || die "... failed"

#echo "running the examples"

#$PYTHON "$DBUS_TOP_SRCDIR"/examples/example-service.py &
#$PYTHON "$DBUS_TOP_SRCDIR"/examples/example-signal-emitter.py &
#$PYTHON "$DBUS_TOP_SRCDIR"/examples/list-system-services.py --session ||
#  die "list-system-services.py --session failed!"
#$PYTHON "$DBUS_TOP_SRCDIR"/examples/example-async-client.py ||
#  die "example-async-client failed!"
#$PYTHON "$DBUS_TOP_SRCDIR"/examples/example-client.py --exit-service ||
#  die "example-client failed!"
#$PYTHON "$DBUS_TOP_SRCDIR"/examples/example-signal-recipient.py --exit-service ||
#  die "example-signal-recipient failed!"

echo "running cross-test (for better diagnostics use mjj29's dbus-test)"

${MAKE:-make} -s cross-test-server > "$DBUS_TOP_BUILDDIR"/test/cross-server.log&
sleep 1
${MAKE:-make} -s cross-test-client > "$DBUS_TOP_BUILDDIR"/test/cross-client.log

if grep . "$DBUS_TOP_BUILDDIR"/test/cross-client.log >/dev/null; then
  :     # OK
else
  die "cross-test client produced no output"
fi
if grep . "$DBUS_TOP_BUILDDIR"/test/cross-server.log >/dev/null; then
  :     # OK
else
  die "cross-test server produced no output"
fi

if grep fail "$DBUS_TOP_BUILDDIR"/test/cross-client.log; then
  die "^^^ Cross-test client reports failures, see test/cross-client.log"
else
  echo "  - cross-test client reported no failures"
fi
if grep untested "$DBUS_TOP_BUILDDIR"/test/cross-server.log; then
  die "^^^ Cross-test server reports incomplete test coverage"
else
  echo "  - cross-test server reported no untested functions"
fi

echo "running test-client.py"
$PYTHON "$DBUS_TOP_SRCDIR"/test/test-client.py || die "test-client.py failed"
echo "running test-signals.py"
$PYTHON "$DBUS_TOP_SRCDIR"/test/test-signals.py || die "test-signals.py failed"

echo "running test-p2p.py"
$PYTHON "$DBUS_TOP_SRCDIR"/test/test-p2p.py || die "... failed"

rm -f "$DBUS_TOP_BUILDDIR"/test/test-service.log
rm -f "$DBUS_TOP_BUILDDIR"/test/cross-client.log
rm -f "$DBUS_TOP_BUILDDIR"/test/cross-server.log
rm -f "$DBUS_TOP_BUILDDIR"/test/monitor.log
exit 0

#! /bin/bash

# Copyright (C) 2003-2005 Red Hat Inc. <http://www.redhat.com/>
# Copyright (C) 2005 Colin Walters
# Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
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

SCRIPTNAME=$0
WRAPPED_SCRIPT=$1
shift

function die()
{
    if ! test -z "$DBUS_SESSION_BUS_PID" ; then
        echo "killing message bus $DBUS_SESSION_BUS_PID" >&2
        kill -9 "$DBUS_SESSION_BUS_PID"
    fi
    echo "$SCRIPTNAME: $*" >&2
    exit 1
}

if test -z "$DBUS_TOP_BUILDDIR" ; then
    die "Must set DBUS_TOP_BUILDDIR"
fi

## convenient to be able to ctrl+C without leaking the message bus process
trap 'die "Received SIGINT"' SIGINT

CONFIG_FILE="$DBUS_TOP_BUILDDIR"/test/tmp-session-bus.conf

unset DBUS_SESSION_BUS_ADDRESS
unset DBUS_SESSION_BUS_PID

echo "Running dbus-launch --sh-syntax --config-file=$CONFIG_FILE" >&2
eval `dbus-launch --sh-syntax --config-file=$CONFIG_FILE`

if test -z "$DBUS_SESSION_BUS_PID" ; then
    die "Failed to launch message bus for introspection generation to run"
fi

echo "Started bus pid $DBUS_SESSION_BUS_PID at $DBUS_SESSION_BUS_ADDRESS" >&2

# Execute wrapped script
echo "Running: $WRAPPED_SCRIPT $*" >&2
"$WRAPPED_SCRIPT" "$@" || die "script \"$WRAPPED_SCRIPT\" failed"

kill -TERM "$DBUS_SESSION_BUS_PID" \
    || die "Message bus vanished! should not have happened" \
    && echo "Killed daemon $DBUS_SESSION_BUS_PID" >&2

sleep 2

## be sure it really died
kill -9 $DBUS_SESSION_BUS_PID > /dev/null 2>&1 || true

exit 0

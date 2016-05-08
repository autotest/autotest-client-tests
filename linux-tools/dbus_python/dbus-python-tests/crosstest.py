# Shared code for the cross-test.

# Copyright (C) 2006 Collabora Ltd. <http://www.collabora.co.uk/>
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

import dbus.service

INTERFACE_SINGLE_TESTS = 'org.freedesktop.DBus.Binding.SingleTests'
INTERFACE_TESTS = 'org.freedesktop.DBus.Binding.Tests'
INTERFACE_SIGNAL_TESTS = 'org.freedesktop.DBus.Binding.TestSignals'
INTERFACE_CALLBACK_TESTS = 'org.freedesktop.DBus.Binding.TestCallbacks'

CROSS_TEST_PATH = '/Test'
CROSS_TEST_BUS_NAME = 'org.freedesktop.DBus.Binding.TestServer'


# Exported by both the client and the server
class SignalTestsImpl(dbus.service.Object):
    @dbus.service.signal(INTERFACE_SIGNAL_TESTS, 't')
    def Triggered(self, parameter):
        pass

    @dbus.service.signal(INTERFACE_SIGNAL_TESTS, 'qd')
    def Trigger(self, parameter1, parameter2):
        pass

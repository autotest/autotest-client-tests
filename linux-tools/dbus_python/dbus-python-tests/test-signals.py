#!/usr/bin/env python

# Copyright (C) 2004 Red Hat Inc. <http://www.redhat.com/>
# Copyright (C) 2005-2007 Collabora Ltd. <http://www.collabora.co.uk/>
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

import sys
import os
import unittest
import time
import logging

builddir = os.path.normpath(os.environ["DBUS_TOP_BUILDDIR"])
pydir = os.path.normpath(os.environ["DBUS_TOP_SRCDIR"])

import dbus
import _dbus_bindings
import dbus.glib
import dbus.service
from gi.repository import GObject as gobject


logging.basicConfig()
logging.getLogger().setLevel(1)
logger = logging.getLogger('test-signals')


pkg = dbus.__file__
if not pkg.startswith(pydir):
    raise Exception("DBus modules (%s) are not being picked up from the package"%pkg)

if not _dbus_bindings.__file__.startswith(builddir):
    raise Exception("DBus modules (%s) are not being picked up from the package"%_dbus_bindings.__file__)


NAME = "org.freedesktop.DBus.TestSuitePythonService"
IFACE = "org.freedesktop.DBus.TestSuiteInterface"
OBJECT = "/org/freedesktop/DBus/TestSuitePythonObject"


class TestSignals(unittest.TestCase):
    def setUp(self):
        logger.info('setUp()')
        self.bus = dbus.SessionBus()
        self.remote_object = self.bus.get_object(NAME, OBJECT)
        self.remote_object_fallback_trivial = self.bus.get_object(NAME,
                OBJECT + '/Fallback')
        self.remote_object_fallback = self.bus.get_object(NAME,
                OBJECT + '/Fallback/Badger')
        self.remote_object_follow = self.bus.get_object(NAME, OBJECT,
                follow_name_owner_changes=True)
        self.iface = dbus.Interface(self.remote_object, IFACE)
        self.iface_follow = dbus.Interface(self.remote_object_follow, IFACE)
        self.fallback_iface = dbus.Interface(self.remote_object_fallback, IFACE)
        self.fallback_trivial_iface = dbus.Interface(
                self.remote_object_fallback_trivial, IFACE)
        self.in_test = None

    def signal_test_impl(self, iface, name, test_removal=False):
        self.in_test = name
        # using append rather than assignment here to avoid scoping issues
        result = []

        def _timeout_handler():
            logger.debug('_timeout_handler for %s: current state %s', name, self.in_test)
            if self.in_test == name:
                main_loop.quit()
        def _signal_handler(s, sender, path):
            logger.debug('_signal_handler for %s: current state %s', name, self.in_test)
            if self.in_test not in (name, name + '+removed'):
                return
            logger.info('Received signal from %s:%s, argument is %r',
                        sender, path, s)
            result.append('received')
            main_loop.quit()
        def _rm_timeout_handler():
            logger.debug('_timeout_handler for %s: current state %s', name, self.in_test)
            if self.in_test == name + '+removed':
                main_loop.quit()

        logger.info('Testing %s', name)
        match = iface.connect_to_signal('SignalOneString', _signal_handler,
                                        sender_keyword='sender',
                                        path_keyword='path')
        logger.info('Waiting for signal...')
        iface.EmitSignal('SignalOneString', 0)
        source_id = gobject.timeout_add(1000, _timeout_handler)
        main_loop.run()
        if not result:
            raise AssertionError('Signal did not arrive within 1 second')
        logger.debug('Removing match')
        match.remove()
        gobject.source_remove(source_id)
        if test_removal:
            self.in_test = name + '+removed'
            logger.info('Testing %s', name)
            result = []
            iface.EmitSignal('SignalOneString', 0)
            source_id = gobject.timeout_add(1000, _rm_timeout_handler)
            main_loop.run()
            if result:
                raise AssertionError('Signal should not have arrived, but did')
            gobject.source_remove(source_id)

    def testFallback(self):
        self.signal_test_impl(self.fallback_iface, 'Fallback')

    def testFallbackTrivial(self):
        self.signal_test_impl(self.fallback_trivial_iface, 'FallbackTrivial')

    def testSignal(self):
        self.signal_test_impl(self.iface, 'Signal')

    def testRemoval(self):
        self.signal_test_impl(self.iface, 'Removal', True)

    def testSignalAgain(self):
        self.signal_test_impl(self.iface, 'SignalAgain')

    def testRemovalAgain(self):
        self.signal_test_impl(self.iface, 'RemovalAgain', True)

    def testSignalF(self):
        self.signal_test_impl(self.iface_follow, 'Signal')

    def testRemovalF(self):
        self.signal_test_impl(self.iface_follow, 'Removal', True)

    def testSignalAgainF(self):
        self.signal_test_impl(self.iface_follow, 'SignalAgain')

    def testRemovalAgainF(self):
        self.signal_test_impl(self.iface_follow, 'RemovalAgain', True)

if __name__ == '__main__':
    main_loop = gobject.MainLoop()
    gobject.threads_init()
    dbus.glib.init_threads()

    logger.info('Starting unit test')
    unittest.main()

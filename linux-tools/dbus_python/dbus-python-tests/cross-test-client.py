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

from __future__ import print_function, unicode_literals
import logging

from gi.repository import GObject as gobject

from dbus import (
    Array, Boolean, Byte, ByteArray, Double, Int16, Int32, Int64,
    Interface, SessionBus, String, UInt16, UInt32, UInt64)
from dbus._compat import is_py2, is_py3
import dbus.glib

if is_py2:
    from dbus import UTF8String

from crosstest import (
    CROSS_TEST_BUS_NAME, CROSS_TEST_PATH, INTERFACE_CALLBACK_TESTS,
    INTERFACE_SIGNAL_TESTS, INTERFACE_SINGLE_TESTS, INTERFACE_TESTS,
    SignalTestsImpl)

if is_py3:
    def make_long(n):
        return n
else:
    def make_long(n):
        return long(n)


logging.basicConfig()
logging.getLogger().setLevel(1)
logger = logging.getLogger('cross-test-client')


class Client(SignalTestsImpl):
    fail_id = 0
    expected = set()

    def quit(self):
        for x in self.expected:
            self.fail_id += 1
            print("%s fail %d" % (x, self.fail_id))
            s = "report %d: reply to %s didn't arrive" % (self.fail_id, x)
            print(s)
            logger.error(s)
        logger.info("asking server to Exit")
        Interface(self.obj, INTERFACE_TESTS).Exit(reply_handler=self.quit_reply_handler, error_handler=self.quit_error_handler)
        # if the server doesn't reply we'll just exit anyway
        gobject.timeout_add(1000, lambda: (loop.quit(), False)[1])

    def quit_reply_handler(self):
        logger.info("server says it will exit")
        loop.quit()

    def quit_error_handler(self, e):
        logger.error("error telling server to quit: %s %s",
                     e.__class__, e)
        loop.quit()

    @dbus.service.method(INTERFACE_CALLBACK_TESTS, 'qd')
    def Response(self, input1, input2):
        logger.info("signal/callback: Response received (%r,%r)",
                    input1, input2)
        self.expected.discard('%s.Trigger' % INTERFACE_SIGNAL_TESTS)
        if (input1, input2) != (42, 23):
            self.fail_id += 1
            print("%s.Trigger fail %d" % 
                  (INTERFACE_SIGNAL_TESTS, self.fail_id))
            s = ("report %d: expected (42,23), got %r"
                 % (self.fail_id, (input1, input2)))
            logger.error(s)
            print(s)
        else:
            print("%s.Trigger pass" % INTERFACE_SIGNAL_TESTS)
        self.quit()

    def assert_method_matches(self, interface, check_fn, check_arg, member, 
                              *args):
        if_obj = Interface(self.obj, interface)
        method = getattr(if_obj, member)
        try:
            real_ret = method(*args)
        except Exception as e:
            self.fail_id += 1
            print("%s.%s fail %d" % (interface, member, self.fail_id))
            s = ("report %d: %s.%s%r: raised %r \"%s\""
                 % (self.fail_id, interface, member, args, e, e))
            print(s)
            logger.error(s)
            __import__('traceback').print_exc()
            return
        try:
            check_fn(real_ret, check_arg)
        except Exception as e:
            self.fail_id += 1
            print("%s.%s fail %d" % (interface, member, self.fail_id))
            s = ("report %d: %s.%s%r: %s"
                 % (self.fail_id, interface, member, args, e))
            print(s)
            logger.error(s)
            return
        print("%s.%s pass" % (interface, member))

    def assert_method_eq(self, interface, ret, member, *args):
        def equals(real_ret, exp):
            if real_ret != exp:
                raise AssertionError('expected %r of class %s, got %r of class %s' % (exp, exp.__class__, real_ret, real_ret.__class__))
            if real_ret != exp:
                raise AssertionError('expected %r, got %r' % (exp, real_ret))
            if not isinstance(exp, (tuple, type(None))):
                if real_ret.variant_level != getattr(exp, 'variant_level', 0):
                    raise AssertionError('expected variant_level=%d, got %r with level %d'
                        % (getattr(exp, 'variant_level', 0), real_ret,
                           real_ret.variant_level))
            if isinstance(exp, list) or isinstance(exp, tuple):
                for i in range(len(exp)):
                    try:
                        equals(real_ret[i], exp[i])
                    except AssertionError as e:
                        if not isinstance(e.args, tuple):
                            e.args = (e.args,)
                        e.args = e.args + ('(at position %d in sequence)' % i,)
                        raise e
            elif isinstance(exp, dict):
                for k in exp:
                    try:
                        equals(real_ret[k], exp[k])
                    except AssertionError as e:
                        if not isinstance(e.args, tuple):
                            e.args = (e.args,)
                        e.args = e.args + ('(at key %r in dict)' % k,)
                        raise e
        self.assert_method_matches(interface, equals, ret, member, *args)

    def assert_InvertMapping_eq(self, interface, expected, member, mapping):
        def check(real_ret, exp):
            for key in exp:
                if key not in real_ret:
                    raise AssertionError('missing key %r' % key)
            for key in real_ret:
                if key not in exp:
                    raise AssertionError('unexpected key %r' % key)
                got = list(real_ret[key])
                wanted = list(exp[key])
                got.sort()
                wanted.sort()
                if got != wanted:
                    raise AssertionError('expected %r => %r, got %r'
                                         % (key, wanted, got))
        self.assert_method_matches(interface, check, expected, member, mapping)

    def triggered_cb(self, param, sender_path):
        logger.info("method/signal: Triggered(%r) by %r",
                    param, sender_path)
        self.expected.discard('%s.Trigger' % INTERFACE_TESTS)
        if sender_path != '/Where/Ever':
            self.fail_id += 1
            print("%s.Trigger fail %d" % (INTERFACE_TESTS, self.fail_id))
            s = ("report %d: expected signal from /Where/Ever, got %r"
                 % (self.fail_id, sender_path))
            print(s)
            logger.error(s)
        elif param != 42:
            self.fail_id += 1
            print("%s.Trigger fail %d" % (INTERFACE_TESTS, self.fail_id))
            s = ("report %d: expected signal param 42, got %r"
                 % (self.fail_id, param))
            print(s)
            logger.error(s)
        else:
            print("%s.Trigger pass" % INTERFACE_TESTS)

    def trigger_returned_cb(self):
        logger.info('method/signal: Trigger() returned')
        # Callback tests
        logger.info("signal/callback: Emitting signal to trigger callback")
        self.expected.add('%s.Trigger' % INTERFACE_SIGNAL_TESTS)
        self.Trigger(UInt16(42), 23.0)
        logger.info("signal/callback: Emitting signal returned")

    def run_client(self):
        bus = SessionBus()
        obj = bus.get_object(CROSS_TEST_BUS_NAME, CROSS_TEST_PATH)
        self.obj = obj

        self.run_synchronous_tests(obj)

        # Signal tests
        logger.info("Binding signal handler for Triggered")
        # FIXME: doesn't seem to work when going via the Interface method
        # FIXME: should be possible to ask the proxy object for its
        # bus name
        bus.add_signal_receiver(self.triggered_cb, 'Triggered',
                                INTERFACE_SIGNAL_TESTS,
                                CROSS_TEST_BUS_NAME,
                                path_keyword='sender_path')
        logger.info("method/signal: Triggering signal")
        self.expected.add('%s.Trigger' % INTERFACE_TESTS)
        Interface(obj, INTERFACE_TESTS).Trigger(
            '/Where/Ever', dbus.UInt64(42), 
            reply_handler=self.trigger_returned_cb, 
            error_handler=self.trigger_error_handler)

    def trigger_error_handler(self, e):
        logger.error("method/signal: %s %s", e.__class__, e)
        Interface(self.obj, INTERFACE_TESTS).Exit()
        self.quit()

    def run_synchronous_tests(self, obj):
        # We can't test that coercion works correctly unless the server has
        # sent us introspection data. Java doesn't :-/
        have_signatures = True

        # "Single tests"
        if have_signatures:
            self.assert_method_eq(INTERFACE_SINGLE_TESTS, 6, 'Sum', [1, 2, 3])
            self.assert_method_eq(INTERFACE_SINGLE_TESTS, 6, 'Sum', 
                                  [b'\x01', b'\x02', b'\x03'])
        self.assert_method_eq(INTERFACE_SINGLE_TESTS, 6, 'Sum', [Byte(1), Byte(2), Byte(3)])
        self.assert_method_eq(INTERFACE_SINGLE_TESTS, 6, 'Sum', ByteArray(b'\x01\x02\x03'))

        # Main tests
        self.assert_method_eq(INTERFACE_TESTS, String('foo', variant_level=1), 'Identity', String('foo'))
        if is_py2:
            self.assert_method_eq(INTERFACE_TESTS, String('foo', variant_level=1), 'Identity', UTF8String('foo'))
        self.assert_method_eq(INTERFACE_TESTS, Byte(42, variant_level=1), 'Identity', Byte(42))
        self.assert_method_eq(INTERFACE_TESTS, Byte(42, variant_level=23), 'Identity', Byte(42, variant_level=23))
        self.assert_method_eq(INTERFACE_TESTS, Double(42.5, variant_level=1), 'Identity', 42.5)
        self.assert_method_eq(INTERFACE_TESTS, Double(-42.5, variant_level=1), 'Identity', -42.5)

        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, String('foo', variant_level=1), 'Identity', 'foo')
            self.assert_method_eq(INTERFACE_TESTS, Byte(42, variant_level=1), 'Identity', Byte(42))
            self.assert_method_eq(INTERFACE_TESTS, Double(42.5, variant_level=1), 'Identity', Double(42.5))
            self.assert_method_eq(INTERFACE_TESTS, Double(-42.5, variant_level=1), 'Identity', -42.5)

        for i in (0, 42, 255):
            self.assert_method_eq(INTERFACE_TESTS, Byte(i), 'IdentityByte', Byte(i))
        for i in (True, False):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityBool', i)

        for i in (-0x8000, 0, 42, 0x7fff):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityInt16', Int16(i))
        for i in (0, 42, 0xffff):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityUInt16', UInt16(i))
        for i in (-0x7fffffff-1, 0, 42, 0x7fffffff):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityInt32', Int32(i))
        for i in (0, 42, 0xffffffff):
            i = make_long(i)
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityUInt32', UInt32(i))
        MANY = 1
        for n in (0x8000, 0x10000, 0x10000, 0x10000):
            MANY *= make_long(n)
        for i in (-MANY, 0, 42, MANY-1):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityInt64', Int64(i))
        for i in (0, 42, 2*MANY - 1):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityUInt64', UInt64(i))

        self.assert_method_eq(INTERFACE_TESTS, 42.3, 'IdentityDouble', 42.3)
        for i in ('', 'foo'):
            self.assert_method_eq(INTERFACE_TESTS, i, 'IdentityString', i)
        for i in ('\xa9', b'\xc2\xa9'):
            self.assert_method_eq(INTERFACE_TESTS, '\xa9', 'IdentityString', i)

        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, Byte(0x42), 
                                  'IdentityByte', b'\x42')
            self.assert_method_eq(INTERFACE_TESTS, True, 'IdentityBool', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityInt16', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityUInt16', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityInt32', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityUInt32', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityInt64', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42, 'IdentityUInt64', 42)
            self.assert_method_eq(INTERFACE_TESTS, 42.0, 'IdentityDouble', 42)

        self.assert_method_eq(INTERFACE_TESTS, [Byte(b'\x01', variant_level=1),
                                                Byte(b'\x02', variant_level=1),
                                                Byte(b'\x03', variant_level=1)],
                                               'IdentityArray',
                                               Array([Byte(b'\x01'),
                                                      Byte(b'\x02'),
                                                      Byte(b'\x03')],
                                                     signature='v'))

        self.assert_method_eq(INTERFACE_TESTS, [Int32(1, variant_level=1),
                                                Int32(2, variant_level=1),
                                                Int32(3, variant_level=1)],
                                               'IdentityArray',
                                               Array([Int32(1),
                                                      Int32(2),
                                                      Int32(3)],
                                                     signature='v'))
        self.assert_method_eq(INTERFACE_TESTS, [String('a', variant_level=1),
                                                String('b', variant_level=1),
                                                String('c', variant_level=1)],
                                               'IdentityArray',
                                               Array([String('a'),
                                                      String('b'),
                                                      String('c')],
                                                     signature='v'))

        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, [Byte(b'\x01', variant_level=1),
                                                    Byte(b'\x02', variant_level=1),
                                                    Byte(b'\x03', variant_level=1)],
                                                   'IdentityArray',
                                                   ByteArray(b'\x01\x02\x03'))
            self.assert_method_eq(INTERFACE_TESTS, [Int32(1, variant_level=1),
                                                    Int32(2, variant_level=1),
                                                    Int32(3, variant_level=1)],
                                                   'IdentityArray',
                                                   [Int32(1),
                                                    Int32(2),
                                                    Int32(3)])
            self.assert_method_eq(INTERFACE_TESTS, [String('a', variant_level=1),
                                                    String('b', variant_level=1),
                                                    String('c', variant_level=1)],
                                                   'IdentityArray',
                                                   ['a','b','c'])

        self.assert_method_eq(INTERFACE_TESTS,
                              [Byte(1), Byte(2), Byte(3)],
                              'IdentityByteArray',
                              ByteArray(b'\x01\x02\x03'))
        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 
                                  'IdentityByteArray', 
                                  [b'\x01', b'\x02', b'\x03'])
        self.assert_method_eq(INTERFACE_TESTS, [False,True], 'IdentityBoolArray', [False,True])
        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, [False,True,True], 'IdentityBoolArray', [0,1,2])

        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt16Array', [Int16(1),Int16(2),Int16(3)])
        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt16Array', [UInt16(1),UInt16(2),UInt16(3)])
        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt32Array', [Int32(1),Int32(2),Int32(3)])
        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt32Array', [UInt32(1),UInt32(2),UInt32(3)])
        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt64Array', [Int64(1),Int64(2),Int64(3)])
        self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt64Array', [UInt64(1),UInt64(2),UInt64(3)])

        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt16Array', [1,2,3])
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt16Array', [1,2,3])
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt32Array', [1,2,3])
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt32Array', [1,2,3])
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityInt64Array', [1,2,3])
            self.assert_method_eq(INTERFACE_TESTS, [1,2,3], 'IdentityUInt64Array', [1,2,3])

        self.assert_method_eq(INTERFACE_TESTS, [1.0,2.5,3.1], 'IdentityDoubleArray', [1.0,2.5,3.1])
        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, [1.0,2.5,3.1], 'IdentityDoubleArray', [1,2.5,3.1])
        self.assert_method_eq(INTERFACE_TESTS, ['a','b','c'], 'IdentityStringArray', ['a','b','c'])
        self.assert_method_eq(INTERFACE_TESTS, 6, 'Sum', [Int32(1),Int32(2),Int32(3)])
        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, 6, 'Sum', [1,2,3])

        self.assert_InvertMapping_eq(INTERFACE_TESTS, {'fps': ['unreal', 'quake'], 'rts': ['warcraft']}, 'InvertMapping', {'unreal': 'fps', 'quake': 'fps', 'warcraft': 'rts'})

        self.assert_method_eq(INTERFACE_TESTS, ('a', 1, 2), 'DeStruct', ('a', UInt32(1), Int16(2)))
        self.assert_method_eq(INTERFACE_TESTS, Array([String('x', variant_level=1)]),
                              'Primitize', [String('x', variant_level=1)])
        self.assert_method_eq(INTERFACE_TESTS, Array([String('x', variant_level=1)]),
                              'Primitize', [String('x', variant_level=23)])
        self.assert_method_eq(INTERFACE_TESTS,
                              Array([String('x', variant_level=1),
                               Byte(1, variant_level=1),
                               Byte(2, variant_level=1)]),
                              'Primitize',
                              Array([String('x'), Byte(1), Byte(2)],
                                    signature='v'))
        self.assert_method_eq(INTERFACE_TESTS,
                              Array([String('x', variant_level=1),
                               Byte(1, variant_level=1),
                               Byte(2, variant_level=1)]),
                              'Primitize',
                              Array([String('x'), Array([Byte(1), Byte(2)])],
                                    signature='v'))
        self.assert_method_eq(INTERFACE_TESTS, Boolean(False), 'Invert', True)
        self.assert_method_eq(INTERFACE_TESTS, Boolean(True), 'Invert', False)
        if have_signatures:
            self.assert_method_eq(INTERFACE_TESTS, Boolean(False), 'Invert', 42)
            self.assert_method_eq(INTERFACE_TESTS, Boolean(True), 'Invert', 0)


if __name__ == '__main__':
    # FIXME: should be possible to export objects without a bus name
    if 0:
        client = Client(dbus.SessionBus(), '/Client')
    else:
        # the Java cross test's interpretation is that the client should be
        # at /Test too
        client = Client(dbus.SessionBus(), '/Test')
    gobject.idle_add(client.run_client)

    loop = gobject.MainLoop()
    logger.info("running...")
    loop.run()
    logger.info("main loop exited.")

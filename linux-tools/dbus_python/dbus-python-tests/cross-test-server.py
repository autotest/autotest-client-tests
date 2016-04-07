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

from __future__ import print_function
import logging

from gi.repository import GObject as gobject

import dbus.glib
from dbus import SessionBus
from dbus.service import BusName
from dbus._compat import is_py2

from crosstest import (
    CROSS_TEST_BUS_NAME, CROSS_TEST_PATH, INTERFACE_CALLBACK_TESTS,
    INTERFACE_SIGNAL_TESTS, INTERFACE_SINGLE_TESTS, INTERFACE_TESTS,
    SignalTestsImpl)


logging.basicConfig()
logging.getLogger().setLevel(1)
logger = logging.getLogger('cross-test-server')


class VerboseSet(set):
    def add(self, thing):
        print('%s ok' % thing)
        set.add(self, thing)


objects = {}


tested_things = VerboseSet()
testable_things = [
        INTERFACE_SINGLE_TESTS + '.Sum',
        INTERFACE_TESTS + '.Identity',
        INTERFACE_TESTS + '.IdentityByte',
        INTERFACE_TESTS + '.IdentityBool',
        INTERFACE_TESTS + '.IdentityInt16',
        INTERFACE_TESTS + '.IdentityUInt16',
        INTERFACE_TESTS + '.IdentityInt32',
        INTERFACE_TESTS + '.IdentityUInt32',
        INTERFACE_TESTS + '.IdentityInt64',
        INTERFACE_TESTS + '.IdentityUInt64',
        INTERFACE_TESTS + '.IdentityDouble',
        INTERFACE_TESTS + '.IdentityString',
        INTERFACE_TESTS + '.IdentityArray',
        INTERFACE_TESTS + '.IdentityByteArray',
        INTERFACE_TESTS + '.IdentityBoolArray',
        INTERFACE_TESTS + '.IdentityInt16Array',
        INTERFACE_TESTS + '.IdentityUInt16Array',
        INTERFACE_TESTS + '.IdentityInt32Array',
        INTERFACE_TESTS + '.IdentityUInt32Array',
        INTERFACE_TESTS + '.IdentityInt64Array',
        INTERFACE_TESTS + '.IdentityUInt64Array',
        INTERFACE_TESTS + '.IdentityDoubleArray',
        INTERFACE_TESTS + '.IdentityStringArray',
        INTERFACE_TESTS + '.Sum',
        INTERFACE_TESTS + '.InvertMapping',
        INTERFACE_TESTS + '.DeStruct',
        INTERFACE_TESTS + '.Primitize',
        INTERFACE_TESTS + '.Trigger',
        INTERFACE_TESTS + '.Exit',
        INTERFACE_TESTS + '.Invert',
        INTERFACE_SIGNAL_TESTS + '.Trigger',
]


class SingleTestsImpl(dbus.service.Object):

    @dbus.service.method(INTERFACE_SINGLE_TESTS, 'ay', 'u')
    def Sum(self, input):
        tested_things.add(INTERFACE_SINGLE_TESTS + '.Sum')
        u = sum(input)
        logger.info('Sum of %r is %r', input, u)
        return u


class TestsImpl(dbus.service.Object):

    def __init__(self, bus_name, service_path, exit_fn):
        self._exit_fn = exit_fn
        dbus.service.Object.__init__(self, bus_name, service_path)

    @dbus.service.method(INTERFACE_TESTS, 'v', 'v')
    def Identity(self, input):
        tested_things.add(INTERFACE_TESTS + '.Identity')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'y', 'y')
    def IdentityByte(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityByte')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'b', 'b')
    def IdentityBool(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityBool')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'n', 'n')
    def IdentityInt16(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt16')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'q', 'q')
    def IdentityUInt16(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt16')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'i', 'i')
    def IdentityInt32(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt32')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'u', 'u')
    def IdentityUInt32(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt32')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'x', 'x')
    def IdentityInt64(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt64')
        return input

    @dbus.service.method(INTERFACE_TESTS, 't', 't')
    def IdentityUInt64(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt64')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'd', 'd')
    def IdentityDouble(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityDouble')
        return input

    @dbus.service.method(INTERFACE_TESTS, 's', 's')
    def IdentityString(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityString')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'av', 'av')
    def IdentityArray(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityArray')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ay', 'ay')
    def IdentityByteArray(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityByteArray')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ab', 'ab')
    def IdentityBoolArray(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityBoolArray')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'an', 'an')
    def IdentityInt16Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt16Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'aq', 'aq')
    def IdentityUInt16Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt16Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ai', 'ai')
    def IdentityInt32Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt32Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'au', 'au')
    def IdentityUInt32Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt32Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ax', 'ax')
    def IdentityInt64Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityInt64Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'at', 'at')
    def IdentityUInt64Array(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityUInt64Array')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ad', 'ad')
    def IdentityDoubleArray(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityDoubleArray')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'as', 'as')
    def IdentityStringArray(self, input):
        tested_things.add(INTERFACE_TESTS + '.IdentityStringArray')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'ai', 'x')
    def Sum(self, input):
        tested_things.add(INTERFACE_TESTS + '.Sum')
        x = sum(input)
        logger.info('Sum of %r is %r', input, x)
        return x


    kwargs = {}
    if is_py2:
        kwargs['utf8_strings'] = True

    @dbus.service.method(INTERFACE_TESTS, 'a{ss}', 'a{sas}', **kwargs)
    def InvertMapping(self, input):
        tested_things.add(INTERFACE_TESTS + '.InvertMapping')
        output = dbus.Dictionary({})
        for k, v in input.items():
            output.setdefault(v, []).append(k)
        return output

    @dbus.service.method(INTERFACE_TESTS, '(sun)', 'sun')
    def DeStruct(self, input):
        tested_things.add(INTERFACE_TESTS + '.DeStruct')
        return input

    @dbus.service.method(INTERFACE_TESTS, 'v', 'av')
    def Primitize(self, input):
        tested_things.add(INTERFACE_TESTS + '.Primitize')
        return list(self.primitivize_helper(input))

    def primitivize_helper(self, input):
        if (isinstance(input, tuple) or isinstance(input, dbus.Struct)
            or isinstance(input, list) or isinstance(input, dbus.Array)):
            for x in input:
                for y in self.primitivize_helper(x):
                    yield y
        elif isinstance(input, dbus.ByteArray):
            for x in input:
                yield dbus.Byte(ord(x))
        elif isinstance(input, dict) or isinstance(input, dbus.Dictionary):
            for x in input:
                for y in self.primitivize_helper(x):
                    yield y
                for y in self.primitivize_helper(input[x]):
                    yield y
        elif input.variant_level > 0:
            yield input.__class__(input)
        else:
            yield input

    @dbus.service.method(INTERFACE_TESTS, 'b', 'b')
    def Invert(self, input):
        tested_things.add(INTERFACE_TESTS + '.Invert')
        return not input

    @dbus.service.method(INTERFACE_TESTS, 'st', '',
                         connection_keyword='conn',
                         **kwargs)
    def Trigger(self, object, parameter, conn=None):
        assert isinstance(object, str)
        logger.info('method/signal: client wants me to emit Triggered(%r) from %r', parameter, object)
        tested_things.add(INTERFACE_TESTS + '.Trigger')
        gobject.idle_add(lambda: self.emit_Triggered_from(conn, object,
                                                          parameter))
    
    def emit_Triggered_from(self, conn, object, parameter):
        assert isinstance(object, str)
        logger.info('method/signal: Emitting Triggered(%r) from %r', parameter, object)
        obj = objects.get(object, None)
        if obj is None:
            obj = SignalTestsImpl(conn, object)
            objects[object] = obj
        obj.Triggered(parameter)
        logger.info('method/signal: Emitted Triggered')

    @dbus.service.method(INTERFACE_TESTS, '', '')
    def Exit(self):
        logger.info('client wants me to Exit')
        tested_things.add(INTERFACE_TESTS + '.Exit')
        for x in testable_things:
            if x not in tested_things:
                print('%s untested' % x)
        logger.info('will quit when idle')
        gobject.idle_add(self._exit_fn)


class Server(SingleTestsImpl, TestsImpl, SignalTestsImpl):

    def triggered_by_client(self, parameter1, parameter2, sender, sender_path):
        # Called when the client emits TestSignals.Trigger from any object.
        logger.info('signal/callback: Triggered by client (%s:%s): (%r,%r)', sender, sender_path, parameter1, parameter2)
        tested_things.add(INTERFACE_SIGNAL_TESTS + '.Trigger')
        dbus.Interface(dbus.SessionBus().get_object(sender, sender_path),
                       INTERFACE_CALLBACK_TESTS).Response(parameter1, parameter2)
        logger.info('signal/callback: Sent Response')



if __name__ == '__main__':
    bus = SessionBus()
    bus_name = BusName(CROSS_TEST_BUS_NAME, bus=bus)
    loop = gobject.MainLoop()
    obj = Server(bus_name, CROSS_TEST_PATH, loop.quit)
    objects[CROSS_TEST_PATH] = obj
    kwargs = {}
    if is_py2:
        kwargs['utf8_strings'] = True
    bus.add_signal_receiver(obj.triggered_by_client,
                            signal_name='Trigger',
                            dbus_interface=INTERFACE_SIGNAL_TESTS,
                            named_service=None,
                            path=None,
                            sender_keyword='sender',
                            path_keyword='sender_path',
                            **kwargs)

    logger.info("running...")
    loop.run()
    logger.info("main loop exited.")

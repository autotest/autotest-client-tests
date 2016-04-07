# pygpgme - a Python wrapper for the gpgme library
# Copyright (C) 2006  James Henstridge
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

import os
import unittest

import gpgme
from tests.util import GpgHomeTestCase

class ContextTestCase(GpgHomeTestCase):

    def test_constructor(self):
        ctx = gpgme.Context()

    def test_protocol(self):
        ctx = gpgme.Context()
        # XXX: this should use symbolic constant names
        self.assertEqual(ctx.protocol, gpgme.PROTOCOL_OpenPGP)
        ctx.protocol = gpgme.PROTOCOL_CMS
        self.assertEqual(ctx.protocol, gpgme.PROTOCOL_CMS)
        ctx.protocol = gpgme.PROTOCOL_OpenPGP
        self.assertEqual(ctx.protocol, gpgme.PROTOCOL_OpenPGP)

        # check error on setting to invalid protocol value
        def set_protocol(ctx, value):
            ctx.protocol = value
        self.assertRaises(gpgme.GpgmeError, set_protocol, ctx, 999)

        def del_protocol(ctx):
            del ctx.protocol
        self.assertRaises(AttributeError, del_protocol, ctx)

    def test_armor(self):
        ctx = gpgme.Context()
        self.assertEqual(ctx.armor, False)
        ctx.armor = True
        self.assertEqual(ctx.armor, True)
        ctx.armor = False
        self.assertEqual(ctx.armor, False)

        def del_armor(ctx):
            del ctx.armor
        self.assertRaises(AttributeError, del_armor, ctx)

    def test_textmode(self):
        ctx = gpgme.Context()
        self.assertEqual(ctx.textmode, False)
        ctx.textmode = True
        self.assertEqual(ctx.textmode, True)
        ctx.textmode = False
        self.assertEqual(ctx.textmode, False)

        def del_textmode(ctx):
            del ctx.textmode
        self.assertRaises(AttributeError, del_textmode, ctx)

    def test_include_certs(self):
        ctx = gpgme.Context()
        # XXX: 20060413 jamesh
        # gpgme 1.0.x and 1.1.x have different default values for
        # include_certs, so I am disabling this test for now.
        #self.assertEqual(ctx.include_certs, 1)
        ctx.include_certs = 2
        self.assertEqual(ctx.include_certs, 2)

        def del_include_certs(ctx):
            del ctx.include_certs
        self.assertRaises(AttributeError, del_include_certs, ctx)

    def test_keylist_mode(self):
        ctx = gpgme.Context()
        self.assertEqual(ctx.keylist_mode, gpgme.KEYLIST_MODE_LOCAL)
        ctx.keylist_mode = gpgme.KEYLIST_MODE_EXTERN
        self.assertEqual(ctx.keylist_mode, gpgme.KEYLIST_MODE_EXTERN)
        ctx.keylist_mode = gpgme.KEYLIST_MODE_LOCAL | gpgme.KEYLIST_MODE_EXTERN
        self.assertEqual(ctx.keylist_mode,
                         gpgme.KEYLIST_MODE_LOCAL | gpgme.KEYLIST_MODE_EXTERN)

        def del_keylist_mode(ctx):
            del ctx.keylist_mode
        self.assertRaises(AttributeError, del_keylist_mode, ctx)

    def test_passphrase_cb(self):
        ctx = gpgme.Context()
        def passphrase_cb(uid_hint, passphrase_info, prev_was_bad, fd):
            pass
        self.assertEqual(ctx.passphrase_cb, None)
        ctx.passphrase_cb = passphrase_cb
        self.assertEqual(ctx.passphrase_cb, passphrase_cb)
        ctx.passphrase_cb = None
        self.assertEqual(ctx.passphrase_cb, None)
        ctx.passphrase_cb = passphrase_cb
        del ctx.passphrase_cb
        self.assertEqual(ctx.passphrase_cb, None)

    def test_progress_cb(self):
        ctx = gpgme.Context()
        def progress_cb(what, type, current, total):
            pass
        self.assertEqual(ctx.progress_cb, None)
        ctx.progress_cb = progress_cb
        self.assertEqual(ctx.progress_cb, progress_cb)
        ctx.progress_cb = None
        self.assertEqual(ctx.progress_cb, None)
        ctx.progress_cb = progress_cb
        del ctx.progress_cb
        self.assertEqual(ctx.progress_cb, None)

    def test_set_engine_info(self):
        # Add a key using the default $GNUPGHOME based keyring.
        ctx = gpgme.Context()
        with self.keyfile('key1.pub') as fp:
            ctx.import_(fp)

        # If we set $GNUPGHOME to a dummy value, we can't read in the
        # keywe just loaded.
        os.environ['GNUPGHOME'] = '/no/such/dir'
        ctx = gpgme.Context()
        self.assertRaises(gpgme.GpgmeError, ctx.get_key,
                          'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # But if we configure the context using set_engine_info(), it
        # will find the key.
        ctx = gpgme.Context()
        ctx.set_engine_info(gpgme.PROTOCOL_OpenPGP, None, self._gpghome)
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertTrue(key)


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

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

import unittest
import os
try:
    from io import BytesIO
except ImportError:
    from StringIO import StringIO as BytesIO
from textwrap import dedent

import gpgme
from tests.util import GpgHomeTestCase

class PassphraseTestCase(GpgHomeTestCase):

    import_keys = ['passphrase.pub', 'passphrase.sec']

    def test_sign_without_passphrase_cb(self):
        ctx = gpgme.Context()
        key = ctx.get_key('EFB052B4230BBBC51914BCBB54DCBBC8DBFB9EB3')
        ctx.signers = [key]
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        try:
            new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_CLEAR)
        except gpgme.GpgmeError as exc:
            self.assertEqual(exc.args[0], gpgme.ERR_SOURCE_GPGME)
            self.assertEqual(exc.args[1], gpgme.ERR_BAD_PASSPHRASE)
        else:
            self.fail('gpgme.GpgmeError not raised')

    def passphrase_cb(self, uid_hint, passphrase_info, prev_was_bad, fd):
        self.uid_hint = uid_hint
        self.passphrase_info = passphrase_info
        self.prev_was_bad = prev_was_bad
        os.write(fd, b'test\n')

    def test_sign_with_passphrase_cb(self):
        ctx = gpgme.Context()
        key = ctx.get_key('EFB052B4230BBBC51914BCBB54DCBBC8DBFB9EB3')
        ctx.signers = [key]
        ctx.passphrase_cb = self.passphrase_cb
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        self.uid_hint = None
        self.passphrase_info = None
        self.prev_was_bad = None
        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_CLEAR)

        # ensure that passphrase_cb has been run, and the data it was passed
        self.assertEqual(self.uid_hint,
            '54DCBBC8DBFB9EB3 Passphrase (test) <passphrase@example.org>')
        self.assertEqual(self.passphrase_info,
            '54DCBBC8DBFB9EB3 54DCBBC8DBFB9EB3 17 0')
        self.assertEqual(self.prev_was_bad, False)

        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_CLEAR)
        self.assertEqual(new_sigs[0].fpr,
                        'EFB052B4230BBBC51914BCBB54DCBBC8DBFB9EB3')

def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

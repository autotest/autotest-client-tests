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

class ProgressTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key1.sec']

    def progress_cb(self, what, type_, current, total):
        self.progress_cb_called = True

    def test_sign_with_progress_cb(self):
        ctx = gpgme.Context()
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.signers = [key]
        ctx.progress_cb = self.progress_cb
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        self.progress_cb_called = False
        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_CLEAR)

        # ensure that progress_cb has been run
        self.assertEqual(self.progress_cb_called, True)

        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_CLEAR)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

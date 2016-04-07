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
try:
    from io import BytesIO
except ImportError:
    from StringIO import StringIO as BytesIO
from textwrap import dedent

import gpgme
from tests.util import GpgHomeTestCase

class ExportTestCase(GpgHomeTestCase):

    import_keys = ['signonly.pub', 'signonly.sec']

    def test_export_by_fingerprint(self):
        ctx = gpgme.Context()
        ctx.armor = True
        keydata = BytesIO()
        ctx.export('15E7CE9BF1771A4ABC550B31F540A569CB935A42', keydata)

        self.assertTrue(keydata.getvalue().startswith(
            b'-----BEGIN PGP PUBLIC KEY BLOCK-----\n'))

    def test_export_by_email(self):
        ctx = gpgme.Context()
        ctx.armor = True
        keydata = BytesIO()
        ctx.export('signonly@example.org', keydata)

        self.assertTrue(keydata.getvalue().startswith(
            b'-----BEGIN PGP PUBLIC KEY BLOCK-----\n'))

    def test_export_by_name(self):
        ctx = gpgme.Context()
        ctx.armor = True
        keydata = BytesIO()
        ctx.export('Sign Only', keydata)

        self.assertTrue(keydata.getvalue().startswith(
            b'-----BEGIN PGP PUBLIC KEY BLOCK-----\n'))


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

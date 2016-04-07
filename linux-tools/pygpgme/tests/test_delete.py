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

import gpgme
from tests.util import GpgHomeTestCase

class DeleteTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key1.sec', 'key2.pub']

    def test_delete_public_key(self):
        ctx = gpgme.Context()
        # key2
        key = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        ctx.delete(key)

        # check that it is deleted
        self.assertRaises(gpgme.GpgmeError, ctx.get_key,
                          '93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')

    def test_delete_public_key_with_secret_key(self):
        ctx = gpgme.Context()
        # key1
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertRaises(gpgme.GpgmeError, ctx.delete, key)

    def test_delete_secret_key(self):
        ctx = gpgme.Context()
        # key1
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.delete(key, True)

    def test_delete_non_existant(self):
        ctx = gpgme.Context()
        # key2
        key = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        ctx.delete(key)

        # delete it again
        try:
            ctx.delete(key)
        except gpgme.GpgmeError as exc:
            self.assertEqual(exc.args[0], gpgme.ERR_SOURCE_GPGME)
            self.assertEqual(exc.args[1], gpgme.ERR_NO_PUBKEY)
        else:
            self.fail('gpgme.GpgmeError was not raised')


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

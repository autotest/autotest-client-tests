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

import gpgme
from tests.util import GpgHomeTestCase

class ImportTestCase(GpgHomeTestCase):

    def test_import_file(self):
        ctx = gpgme.Context()
        with self.keyfile('key1.pub') as fp:
            result = ctx.import_(fp)
        self.assertEqual(result.considered, 1)
        self.assertEqual(result.no_user_id, 0)
        self.assertEqual(result.imported, 1)
        self.assertEqual(result.imported_rsa, 0)
        self.assertEqual(result.unchanged, 0)
        self.assertEqual(result.new_user_ids, 0)
        self.assertEqual(result.new_sub_keys, 0)
        self.assertEqual(result.new_signatures, 0)
        self.assertEqual(result.new_revocations, 0)
        self.assertEqual(result.secret_read, 0)
        self.assertEqual(result.secret_imported, 0)
        self.assertEqual(result.secret_unchanged, 0)
        self.assertEqual(result.skipped_new_keys, 0)
        self.assertEqual(result.not_imported, 0)
        self.assertEqual(len(result.imports), 1)
        self.assertEqual(result.imports[0],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW))
        # can we get the public key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')

    def test_import_secret_file(self):
        ctx = gpgme.Context()
        with self.keyfile('key1.sec') as fp:
            result = ctx.import_(fp)
        self.assertEqual(result.considered, 1)
        self.assertEqual(result.no_user_id, 0)
        self.assertEqual(result.imported, 1)
        self.assertEqual(result.imported_rsa, 0)
        self.assertEqual(result.unchanged, 0)
        self.assertEqual(result.new_user_ids, 0)
        self.assertEqual(result.new_sub_keys, 0)
        self.assertEqual(result.new_signatures, 0)
        self.assertEqual(result.new_revocations, 0)
        self.assertEqual(result.secret_read, 1)
        self.assertEqual(result.secret_imported, 1)
        self.assertEqual(result.secret_unchanged, 0)
        self.assertEqual(result.skipped_new_keys, 0)
        self.assertEqual(result.not_imported, 0)
        self.assertEqual(len(result.imports), 2)
        self.assertEqual(result.imports[0],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW | gpgme.IMPORT_SECRET))
        self.assertEqual(result.imports[1],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW))
        # can we get the public key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        # can we get the secret key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4', True)

    def test_import_stringio(self):
        with self.keyfile('key1.pub') as fp:
            data = fp.read()
        fp = BytesIO(data)
        ctx = gpgme.Context()
        result = ctx.import_(fp)
        self.assertEqual(len(result.imports), 1)
        self.assertEqual(result.imports[0],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW))
        # can we get the public key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')

    def test_import_concat(self):
        keys = []
        for filename in ['key1.pub', 'key1.sec', 'key2.pub']:
            with self.keyfile(filename) as fp:
                keys.append(fp.read())
        fp = BytesIO(b'\n'.join(keys))
        ctx = gpgme.Context()
        result = ctx.import_(fp)
        self.assertEqual(result.considered, 3)
        self.assertEqual(result.no_user_id, 0)
        self.assertEqual(result.imported, 2)
        self.assertEqual(result.imported_rsa, 1)
        self.assertEqual(result.unchanged, 0)
        self.assertEqual(result.new_user_ids, 0)
        self.assertEqual(result.new_sub_keys, 0)
        self.assertEqual(result.new_signatures, 1)
        self.assertEqual(result.new_revocations, 0)
        self.assertEqual(result.secret_read, 1)
        self.assertEqual(result.secret_imported, 1)
        self.assertEqual(result.secret_unchanged, 0)
        self.assertEqual(result.skipped_new_keys, 0)
        self.assertEqual(result.not_imported, 0)
        self.assertEqual(len(result.imports), 4)
        self.assertEqual(result.imports[0],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW))
        self.assertEqual(result.imports[1],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_NEW | gpgme.IMPORT_SECRET))
        self.assertEqual(result.imports[2],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4',
                          None, gpgme.IMPORT_SIG))
        self.assertEqual(result.imports[3],
                         ('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F',
                          None, gpgme.IMPORT_NEW))
        # can we get the public keys?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        key = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        # can we get the secret key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4', True)

    def test_import_empty(self):
        fp = BytesIO(b'')
        ctx = gpgme.Context()
        result = ctx.import_(fp)
        self.assertEqual(result.considered, 0)
        self.assertEqual(len(result.imports), 0)

    def test_import_twice(self):
        ctx = gpgme.Context()
        with self.keyfile('key1.pub') as fp:
            result = ctx.import_(fp)

        with self.keyfile('key1.pub') as fp:
            result = ctx.import_(fp)

        self.assertEqual(result.considered, 1)
        self.assertEqual(result.no_user_id, 0)
        self.assertEqual(result.imported, 0)
        self.assertEqual(result.imported_rsa, 0)
        self.assertEqual(result.unchanged, 1)
        self.assertEqual(result.new_user_ids, 0)
        self.assertEqual(result.new_sub_keys, 0)
        self.assertEqual(result.new_signatures, 0)
        self.assertEqual(result.new_revocations, 0)
        self.assertEqual(result.secret_read, 0)
        self.assertEqual(result.secret_imported, 0)
        self.assertEqual(result.secret_unchanged, 0)
        self.assertEqual(result.skipped_new_keys, 0)
        self.assertEqual(result.not_imported, 0)
        self.assertEqual(len(result.imports), 1)
        self.assertEqual(result.imports[0],
                         ('E79A842DA34A1CA383F64A1546BB55F0885C65A4', None, 0))
        # can we get the public key?
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')

def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

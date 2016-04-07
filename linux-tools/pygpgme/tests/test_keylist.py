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

class KeylistTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key2.pub', 'revoked.pub', 'signonly.pub',
                   'key1.sec']

    def test_listall(self):
        ctx = gpgme.Context()
        keyids = set(key.subkeys[0].keyid for key in ctx.keylist())
        self.assertTrue(keyids, set(['46BB55F0885C65A4',
                                     '2CF46B7FC97E6B0F',
                                     'F540A569CB935A42',
                                     '2EF658C987754368']))

    def test_list_by_email(self):
        ctx = gpgme.Context()
        keyids = set(key.subkeys[0].keyid
                     for key in ctx.keylist('key1@example.org'))
        self.assertTrue(keyids, set(['46BB55F0885C65A4']))
        keyids = set(key.subkeys[0].keyid
                     for key in ctx.keylist(['key1@example.org',
                                             'signonly@example.com']))
        self.assertTrue(keyids, set(['46BB55F0885C65A4', 'F540A569CB935A42']))

    def test_list_by_name(self):
        ctx = gpgme.Context()
        keyids = set(key.subkeys[0].keyid
                     for key in ctx.keylist('Key 1'))
        self.assertTrue(keyids, set(['46BB55F0885C65A4']))

    def test_list_by_email_substring(self):
        ctx = gpgme.Context()
        keyids = set(key.subkeys[0].keyid
                     for key in ctx.keylist('@example.org'))
        self.assertTrue(keyids, set(['46BB55F0885C65A4',
                                     '2CF46B7FC97E6B0F',
                                     'F540A569CB935A42',
                                     '2EF658C987754368']))

    def test_list_secret(self):
        ctx = gpgme.Context()
        keyids = set(key.subkeys[0].keyid
                     for key in ctx.keylist(None, True))
        self.assertTrue(keyids, set(['46BB55F0885C65A4']))


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

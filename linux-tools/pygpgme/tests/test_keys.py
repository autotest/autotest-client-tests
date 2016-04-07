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

class KeyTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key2.pub', 'revoked.pub', 'signonly.pub']

    def test_key1(self):
        ctx = gpgme.Context()
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(key.revoked, False)
        self.assertEqual(key.expired, False)
        self.assertEqual(key.invalid, False)
        self.assertEqual(key.can_encrypt, True)
        self.assertEqual(key.can_sign, True)
        self.assertEqual(key.can_certify, True)
        self.assertEqual(key.secret, False)
        self.assertEqual(key.can_authenticate, False)
        self.assertEqual(key.protocol, gpgme.PROTOCOL_OpenPGP)
        self.assertEqual(len(key.subkeys), 2)
        self.assertEqual(len(key.uids), 1)

        self.assertEqual(key.subkeys[0].revoked, False)
        self.assertEqual(key.subkeys[0].expired, False)
        self.assertEqual(key.subkeys[0].disabled, False)
        self.assertEqual(key.subkeys[0].invalid, False)
        self.assertEqual(key.subkeys[0].can_encrypt, False)
        self.assertEqual(key.subkeys[0].can_sign, True)
        self.assertEqual(key.subkeys[0].can_certify, True)
        self.assertEqual(key.subkeys[0].secret, False)
        self.assertEqual(key.subkeys[0].can_authenticate, False)
        self.assertEqual(key.subkeys[0].pubkey_algo, gpgme.PK_DSA)
        self.assertEqual(key.subkeys[0].length, 1024)
        self.assertEqual(key.subkeys[0].keyid, '46BB55F0885C65A4')
        self.assertEqual(key.subkeys[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(key.subkeys[0].timestamp, 1137568227)
        self.assertEqual(key.subkeys[0].expires, 0)

        self.assertEqual(key.subkeys[1].revoked, False)
        self.assertEqual(key.subkeys[1].expired, False)
        self.assertEqual(key.subkeys[1].disabled, False)
        self.assertEqual(key.subkeys[1].invalid, False)
        self.assertEqual(key.subkeys[1].can_encrypt, True)
        self.assertEqual(key.subkeys[1].can_sign, False)
        self.assertEqual(key.subkeys[1].can_certify, False)
        self.assertEqual(key.subkeys[1].secret, False)
        self.assertEqual(key.subkeys[1].can_authenticate, False)
        self.assertEqual(key.subkeys[1].pubkey_algo, gpgme.PK_ELG_E)
        self.assertEqual(key.subkeys[1].length, 2048)
        self.assertEqual(key.subkeys[1].keyid, '659A6AC69BC3B085')
        # Some versions of libgpgme fill this one in and others don't
        #self.assertEqual(key.subkeys[1].fpr, None)
        self.assertEqual(key.subkeys[1].timestamp, 1137568234)
        self.assertEqual(key.subkeys[1].expires, 0)

        self.assertEqual(key.uids[0].revoked, False)
        self.assertEqual(key.uids[0].invalid, False)
        self.assertEqual(key.uids[0].validity, 0)
        self.assertEqual(key.uids[0].uid, 'Key 1 <key1@example.org>')
        self.assertEqual(key.uids[0].name, 'Key 1')
        self.assertEqual(key.uids[0].email, 'key1@example.org')
        self.assertEqual(key.uids[0].comment, '')

    def test_key2(self):
        ctx = gpgme.Context()
        key = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        self.assertEqual(key.revoked, False)
        self.assertEqual(key.expired, False)
        self.assertEqual(key.invalid, False)
        self.assertEqual(key.can_encrypt, True)
        self.assertEqual(key.can_sign, True)
        self.assertEqual(key.can_certify, True)
        self.assertEqual(key.secret, False)
        self.assertEqual(key.can_authenticate, False)
        self.assertEqual(key.protocol, gpgme.PROTOCOL_OpenPGP)
        self.assertEqual(len(key.subkeys), 2)
        self.assertEqual(len(key.uids), 1)

        self.assertEqual(key.subkeys[0].revoked, False)
        self.assertEqual(key.subkeys[0].expired, False)
        self.assertEqual(key.subkeys[0].disabled, False)
        self.assertEqual(key.subkeys[0].invalid, False)
        self.assertEqual(key.subkeys[0].can_encrypt, False)
        self.assertEqual(key.subkeys[0].can_sign, True)
        self.assertEqual(key.subkeys[0].can_certify, True)
        self.assertEqual(key.subkeys[0].secret, False)
        self.assertEqual(key.subkeys[0].can_authenticate, False)
        self.assertEqual(key.subkeys[0].pubkey_algo, gpgme.PK_RSA)
        self.assertEqual(key.subkeys[0].length, 4096)
        self.assertEqual(key.subkeys[0].keyid, '2CF46B7FC97E6B0F')
        self.assertEqual(key.subkeys[0].fpr,
                         '93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        self.assertEqual(key.subkeys[0].timestamp, 1137568343)
        self.assertEqual(key.subkeys[0].expires, 0)

        self.assertEqual(key.subkeys[1].revoked, False)
        self.assertEqual(key.subkeys[1].expired, False)
        self.assertEqual(key.subkeys[1].disabled, False)
        self.assertEqual(key.subkeys[1].invalid, False)
        self.assertEqual(key.subkeys[1].can_encrypt, True)
        self.assertEqual(key.subkeys[1].can_sign, False)
        self.assertEqual(key.subkeys[1].can_certify, False)
        self.assertEqual(key.subkeys[1].secret, False)
        self.assertEqual(key.subkeys[1].can_authenticate, False)
        self.assertEqual(key.subkeys[1].pubkey_algo, gpgme.PK_RSA)
        self.assertEqual(key.subkeys[1].length, 4096)
        self.assertEqual(key.subkeys[1].keyid, 'A95221D00DCBDD64')
        # Some versions of libgpgme fill this one in and others don't
        #self.assertEqual(key.subkeys[1].fpr, None)
        self.assertEqual(key.subkeys[1].timestamp, 1137568395)
        self.assertEqual(key.subkeys[1].expires, 0)

        self.assertEqual(key.uids[0].revoked, False)
        self.assertEqual(key.uids[0].invalid, False)
        self.assertEqual(key.uids[0].validity, 0)
        self.assertEqual(key.uids[0].uid, 'Key 2 <key2@example.org>')
        self.assertEqual(key.uids[0].name, 'Key 2')
        self.assertEqual(key.uids[0].email, 'key2@example.org')
        self.assertEqual(key.uids[0].comment, '')

    def test_revoked(self):
        ctx = gpgme.Context()
        key = ctx.get_key('B6525A39EB81F88B4D2CFB3E2EF658C987754368')
        self.assertEqual(key.revoked, True)
        self.assertEqual(key.expired, False)
        self.assertEqual(key.invalid, False)
        self.assertEqual(key.can_encrypt, False)
        self.assertEqual(key.can_sign, True)
        self.assertEqual(key.can_certify, True)
        self.assertEqual(key.secret, False)
        self.assertEqual(key.can_authenticate, False)
        self.assertEqual(key.protocol, gpgme.PROTOCOL_OpenPGP)
        self.assertEqual(len(key.subkeys), 2)
        self.assertEqual(len(key.uids), 1)

        self.assertEqual(key.subkeys[0].revoked, True)
        self.assertEqual(key.subkeys[0].expired, False)
        self.assertEqual(key.subkeys[0].disabled, False)
        self.assertEqual(key.subkeys[0].invalid, False)
        self.assertEqual(key.subkeys[0].can_encrypt, False)
        self.assertEqual(key.subkeys[0].can_sign, True)
        self.assertEqual(key.subkeys[0].can_certify, True)
        self.assertEqual(key.subkeys[0].secret, False)
        self.assertEqual(key.subkeys[0].can_authenticate, False)
        self.assertEqual(key.subkeys[0].pubkey_algo, gpgme.PK_DSA)
        self.assertEqual(key.subkeys[0].length, 1024)
        self.assertEqual(key.subkeys[0].keyid, '2EF658C987754368')
        self.assertEqual(key.subkeys[0].fpr,
                         'B6525A39EB81F88B4D2CFB3E2EF658C987754368')
        self.assertEqual(key.subkeys[0].timestamp, 1137569043)
        self.assertEqual(key.subkeys[0].expires, 0)

        self.assertEqual(key.subkeys[1].revoked, True)
        self.assertEqual(key.subkeys[1].expired, False)
        self.assertEqual(key.subkeys[1].disabled, False)
        self.assertEqual(key.subkeys[1].invalid, False)
        self.assertEqual(key.subkeys[1].can_encrypt, True)
        self.assertEqual(key.subkeys[1].can_sign, False)
        self.assertEqual(key.subkeys[1].can_certify, False)
        self.assertEqual(key.subkeys[1].secret, False)
        self.assertEqual(key.subkeys[1].can_authenticate, False)
        self.assertEqual(key.subkeys[1].pubkey_algo, gpgme.PK_ELG_E)
        self.assertEqual(key.subkeys[1].length, 1024)
        self.assertEqual(key.subkeys[1].keyid, 'E50B59CF50CE4D54')
        # Some versions of libgpgme fill this one in and others don't
        #self.assertEqual(key.subkeys[1].fpr, None)
        self.assertEqual(key.subkeys[1].timestamp, 1137569047)
        self.assertEqual(key.subkeys[1].expires, 0)

        self.assertEqual(key.uids[0].revoked, True)
        self.assertEqual(key.uids[0].invalid, False)
        self.assertEqual(key.uids[0].validity, 0)
        self.assertEqual(key.uids[0].uid, 'Revoked <revoked@example.org>')
        self.assertEqual(key.uids[0].name, 'Revoked')
        self.assertEqual(key.uids[0].email, 'revoked@example.org')
        self.assertEqual(key.uids[0].comment, '')

    def test_signonly(self):
        ctx = gpgme.Context()
        key = ctx.get_key('15E7CE9BF1771A4ABC550B31F540A569CB935A42')
        self.assertEqual(key.revoked, False)
        self.assertEqual(key.expired, False)
        self.assertEqual(key.invalid, False)
        self.assertEqual(key.can_encrypt, False)
        self.assertEqual(key.can_sign, True)
        self.assertEqual(key.can_certify, True)
        self.assertEqual(key.secret, False)
        self.assertEqual(key.can_authenticate, False)
        self.assertEqual(key.protocol, gpgme.PROTOCOL_OpenPGP)
        self.assertEqual(len(key.subkeys), 1)
        self.assertEqual(len(key.uids), 2)

        self.assertEqual(key.subkeys[0].revoked, False)
        self.assertEqual(key.subkeys[0].expired, False)
        self.assertEqual(key.subkeys[0].disabled, False)
        self.assertEqual(key.subkeys[0].invalid, False)
        self.assertEqual(key.subkeys[0].can_encrypt, False)
        self.assertEqual(key.subkeys[0].can_sign, True)
        self.assertEqual(key.subkeys[0].can_certify, True)
        self.assertEqual(key.subkeys[0].secret, False)
        self.assertEqual(key.subkeys[0].can_authenticate, False)
        self.assertEqual(key.subkeys[0].pubkey_algo, gpgme.PK_RSA)
        self.assertEqual(key.subkeys[0].length, 4096)
        self.assertEqual(key.subkeys[0].keyid, 'F540A569CB935A42')
        self.assertEqual(key.subkeys[0].fpr,
                         '15E7CE9BF1771A4ABC550B31F540A569CB935A42')
        self.assertEqual(key.subkeys[0].timestamp, 1137568835)
        self.assertEqual(key.subkeys[0].expires, 0)

        self.assertEqual(key.uids[0].revoked, False)
        self.assertEqual(key.uids[0].invalid, False)
        self.assertEqual(key.uids[0].validity, 0)
        self.assertEqual(key.uids[0].uid, 'Sign Only <signonly@example.org>')
        self.assertEqual(key.uids[0].name, 'Sign Only')
        self.assertEqual(key.uids[0].email, 'signonly@example.org')
        self.assertEqual(key.uids[0].comment, '')

        self.assertEqual(key.uids[1].revoked, False)
        self.assertEqual(key.uids[1].invalid, False)
        self.assertEqual(key.uids[1].validity, 0)
        self.assertEqual(key.uids[1].uid,
                         'Sign Only (work address) <signonly@example.com>')
        self.assertEqual(key.uids[1].name, 'Sign Only')
        self.assertEqual(key.uids[1].email, 'signonly@example.com')
        self.assertEqual(key.uids[1].comment, 'work address')


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

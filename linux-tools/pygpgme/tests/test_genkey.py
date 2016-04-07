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


# See /usr/share/doc/gnupg/DETAILS.gz

# XXX we are using a passwordless key because the passphrase_cb
# backend seems to be currently broken.

signing_only_param = """
<GnupgKeyParms format="internal">
  Key-Type: RSA
  Key-Usage: sign
  Key-Length: 1024
  Name-Real: Testing
  Name-Comment: comment
  Name-Email: someone@example.com
  Expire-Date: 0
</GnupgKeyParms>
"""


class GenerateKeyTestCase(GpgHomeTestCase):

    def assertCanSign(self, key):
        """Check that the given key can be used to create signatures."""
        ctx = gpgme.Context()
        ctx.signers = [key]

        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        ctx.armor = True
        new_sigs = ctx.sign(
            plaintext, signature, gpgme.SIG_MODE_DETACH)

        signature.seek(0)
        plaintext.seek(0)

        sigs = ctx.verify(signature, plaintext, None)
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].fpr, key.subkeys[0].fpr)

    def _test_generate_signing_only_keys(self):
        ctx = gpgme.Context()
        result = ctx.genkey(signing_only_param)

        self.assertEqual(result.primary, True)
        self.assertEqual(result.sub, False)
        self.assertEqual(len(result.fpr), 40)

        # The generated key is part of the current keyring.
        key = ctx.get_key(result.fpr, True)
        self.assertEqual(key.revoked, False)
        self.assertEqual(key.expired, False)
        self.assertEqual(key.secret, True)
        self.assertEqual(key.protocol, gpgme.PROTOCOL_OpenPGP)

        # Single signing-only RSA key.
        self.assertEqual(len(key.subkeys), 1)
        subkey = key.subkeys[0]
        self.assertEqual(subkey.secret, True)
        self.assertEqual(subkey.pubkey_algo, gpgme.PK_RSA)
        self.assertEqual(subkey.length, 1024)

        self.assertEqual(key.can_sign, True)
        self.assertEqual(key.can_encrypt, False)

        # The only UID available matches the given parameters.
        [uid] = key.uids
        self.assertEqual(uid.name, 'Testing')
        self.assertEqual(uid.comment, 'comment')
        self.assertEqual(uid.email, 'someone@example.com')

        # Finally check if the generated key can perform signatures.
        self.assertCanSign(key)

    def test_invalid_parameters(self):
        ctx = gpgme.Context()
        try:
            ctx.genkey('garbage parameters')
        except gpgme.GpgmeError as exc:
            self.assertTrue(hasattr(exc, "result"))
            result = exc.result
            self.assertEqual(result.primary, False)
            self.assertEqual(result.sub, False)
            self.assertEqual(result.fpr, None)
        else:
            self.fail("GpgmeError not raised")


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)


if __name__ == '__main__':
    unittest.main()

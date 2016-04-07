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
try:
    from io import BytesIO
except ImportError:
    from StringIO import StringIO as BytesIO
from textwrap import dedent

import gpgme
from tests.util import GpgHomeTestCase

class EncryptDecryptTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key1.sec', 'key2.pub', 'key2.sec',
                   'signonly.pub', 'signonly.sec']

    def test_decrypt(self):
        ciphertext = BytesIO(dedent('''
            -----BEGIN PGP MESSAGE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            hQIMA6lSIdANy91kARAAtXjViihD6DVBAYGdVs0a2sMPGRXjIR5Tw1ONKx4MtKn+
            pydR+/+0rBRGaQXe/mMODA8gqADQjz7PcTMWBa7ja969+K2nw7j5DUIMatonQVMf
            vpc7ze5hovZ1jXYAgmmXdUzDmk8ZkpHaEc5mMMAHYKFn+mm37AFY5JUjg2Ae9k3H
            29t+pW+n9ncn/QBImW3oVslZ8Fza1xOIWZTUrmvtU0vELdlIxy+d945bvD9EhmTK
            zRrD5m8V1etWINO2tE1Xhd4lV1KxncHzWafXLB5BKprztTqFUXNPAfnucYIczDon
            5VvkOz3WAtl/93o85hUKhbgGK0dvU3m+bj620ZUE5oDpPB4l1CiO5RqUFYtyN4LF
            OSAceVOh7X764VLtpAzuOpNfTYgvzIFJqrFOZHlf3XJRdGdpJuxMe8BwhdLyDscx
            pap4QxajOUSUAeS45x6ERA7xHO0QOwXZNzoxiOt9KRaoIhEacu70A9xRcGNJfZE2
            3z/AEMKr2CK6ny9/S8UQEhNvn1/gYfSXakFjWjM6PUXJSnz8WGjpFKKITpex3WBz
            m/X8bKgG3fT92zqJdYocrl4wgz4Dt3+KirnGG4gITxaEYpTT0y6l6NAO60De0oRh
            yqk+ulj2pvAlA82Ph0vTGZ9uOQGbrfN+NhwsG0HMNq+vmjShS1jJbSfoEt1AAIPS
            RwGMq7SDk/V7nhKqZcxeIWdtRIgFvEf0KljthkOZxT/GozNjQclak7Kt69K2qyvt
            XUfidNAhuOmeZ4pF31qSFiAnKRbzjzHp
            =1s5N
            -----END PGP MESSAGE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        ctx.decrypt(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'hello world\n')

    def test_decrypt_verify(self):
        ciphertext = BytesIO(dedent('''
            -----BEGIN PGP MESSAGE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            hQIMA6lSIdANy91kAQ/9GGQxL/OWvxrTchSMmIhsvwONJNlFE5cMIC0xejY4eN+t
            HtTg8V1fWXLRw7WY6FNFLeoR2hzqaZWw15lU55TmSJfJmK2mdUZu/IhSpCUFMEFW
            ZQpxslKq7N+S8NZHgq1WG32Ar1auOEflBQUMhj7sRSAtkvU7fWrTwf4Q4mcIV68P
            LiAAQoKxXNNVam9+EV/b3kx3bnJPKTn+ArpJf5Im+5XOGOeu9Ll0QUTbicgFhfpR
            esR6dKI/Ji5FGIu01kYNrDjDeMcJuzI52kNNoT+GJ72R+Gp4bZk2ycd+eVo3eeUW
            klO8K+7E5bd5ni+1H+ZWbVp9bn7Q++mFP6Mruv+v9Di5mvFXxMoFuB/8NzcilFVt
            h5VOexW1OaZk2bMp9bXVja/N7Y1oAADhINk0feaKkwYVOBJU9kJtL2O1WQui85Q3
            2dsL0YRJiR6mXesTezglZO44gsVAvCH8RUCtBnfEazfBg4jhcCHy6ooDgd0M4vcw
            xG4U7IyDU5xyLi9QrTaSg5LzzwNFqb5k/lTemZw3ob3uwZinWewASLwn5N5OPVRs
            gFT0eL0TfvDzHURsM/7QDvq9HX6JS7buyOlr5cZAsdSvm0FyE6YOkSvZR2jwp3vV
            jfs7RHjq9V7jzPVVKHnWEDoJfchkT/3KyMRCIM/ukBk9MwTZTIJRhjTA2Xd4kWTS
            kQEaU/OjumXPtw/T1pUH23nAkVssHsj8qgtxkFSmG/wrwNmfYx4tDhvgsHMJhar9
            hqQKBMsGmLD6RNWKhF/LryNBKI2IRgJabKKYbbOsydom/hw8ZF4aWaZTcCBMoBB2
            nhOi8WEIeWp93FGfHBa60nSBNGwgt24NmoFaXMjnCrJY/yK0L0MAajUC150OhtvG
            OSk=
            =fl3U
            -----END PGP MESSAGE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        sigs = ctx.decrypt_verify(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'hello world\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].notations, [])
        self.assertEqual(sigs[0].timestamp, 1138049495)
        self.assertEqual(sigs[0].exp_timestamp, 0)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_encrypt(self):
        plaintext = BytesIO(b'Hello World\n')
        ciphertext = BytesIO()
        ctx = gpgme.Context()
        recipient = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        ctx.encrypt([recipient], gpgme.ENCRYPT_ALWAYS_TRUST,
                    plaintext, ciphertext)

        # rewind ciphertext buffer, and try to decrypt:
        ciphertext.seek(0)
        plaintext = BytesIO()
        ctx.decrypt(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')

    def test_encrypt_armor(self):
        plaintext = BytesIO(b'Hello World\n')
        ciphertext = BytesIO()
        ctx = gpgme.Context()
        ctx.armor = True
        recipient = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        ctx.encrypt([recipient], gpgme.ENCRYPT_ALWAYS_TRUST,
                    plaintext, ciphertext)

        # rewind ciphertext buffer, and try to decrypt:
        ciphertext.seek(0)
        plaintext = BytesIO()
        ctx.decrypt(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')

    def test_encrypt_symmetric(self):
        plaintext = BytesIO(b'Hello World\n')
        ciphertext = BytesIO()
        def passphrase(uid_hint, passphrase_info, prev_was_bad, fd):
            os.write(fd, b'Symmetric passphrase\n')
        ctx = gpgme.Context()
        ctx.armor = True
        ctx.passphrase_cb = passphrase
        #ctx.encrypt(None, 0, plaintext, ciphertext)
	recipient = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F') 
	ctx.encrypt([recipient], gpgme.ENCRYPT_ALWAYS_TRUST,plaintext, ciphertext) 
        self.assertTrue(
            ciphertext.getvalue().startswith(b'-----BEGIN PGP MESSAGE-----'))

        # Rewind ciphertext buffer and try to decrypt it:
        ciphertext.seek(0)
        plaintext = BytesIO()
        ctx.decrypt(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')

    def test_encrypt_sign(self):
        plaintext = BytesIO(b'Hello World\n')
        ciphertext = BytesIO()
        ctx = gpgme.Context()
        ctx.armor = True
        signer = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        recipient = ctx.get_key('93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        ctx.signers = [signer]
        new_sigs = ctx.encrypt_sign([recipient], gpgme.ENCRYPT_ALWAYS_TRUST,
                                    plaintext, ciphertext)

        self.assertEqual(len(new_sigs), 1)
        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_NORMAL)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # rewind ciphertext buffer, and try to decrypt:
        ciphertext.seek(0)
        plaintext = BytesIO()
        sigs = ctx.decrypt_verify(ciphertext, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_encrypt_to_signonly(self):
        plaintext = BytesIO(b'Hello World\n')
        ciphertext = BytesIO()
        ctx = gpgme.Context()
        recipient = ctx.get_key('15E7CE9BF1771A4ABC550B31F540A569CB935A42')
        try:
            ctx.encrypt([recipient], gpgme.ENCRYPT_ALWAYS_TRUST,
                        plaintext, ciphertext)
        except gpgme.GpgmeError as exc:
            self.assertEqual(exc.args[0], gpgme.ERR_SOURCE_UNKNOWN)
            self.assertEqual(exc.args[1], gpgme.ERR_GENERAL)
        else:
            self.fail('gpgme.GpgmeError not raised')


def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

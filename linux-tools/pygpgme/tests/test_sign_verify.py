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

class SignVerifyTestCase(GpgHomeTestCase):

    import_keys = ['key1.pub', 'key1.sec', 'key2.pub', 'key2.sec',
                   'signonly.pub', 'signonly.sec']

    def test_verify_normal(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP MESSAGE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            owGbwMvMwCTotjv0Q0dM6hLG00JJDM7nNx31SM3JyVcIzy/KSeHqsGdmBQvCVAky
            pR9hmGfw0qo3bfpWZwun5euYAsUcVkyZMJlhfvkU6UBjD8WF9RfeND05zC/TK+H+
            EQA=
            =HCW0
            -----END PGP MESSAGE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        sigs = ctx.verify(signature, None, plaintext)

        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].notations, [])
        self.assertEqual(sigs[0].timestamp, 1137685189)
        self.assertEqual(sigs[0].exp_timestamp, 0)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_verify_detached(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP SIGNATURE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            iD8DBQBDz7ReRrtV8IhcZaQRAtuUAJwMiJeS5QPohToxA3+vp+z5c3jr1wCdHhGP
            hhSTiguzgSYNwKSuV6SLGOM=
            =dyZS
            -----END PGP SIGNATURE-----
            ''').encode('ASCII'))
        signed_text = BytesIO(b'Hello World\n')
        ctx = gpgme.Context()
        sigs = ctx.verify(signature, signed_text, None)

        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].notations, [])
        self.assertEqual(sigs[0].timestamp, 1137685598)
        self.assertEqual(sigs[0].exp_timestamp, 0)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_verify_clearsign(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP SIGNED MESSAGE-----
            Hash: SHA1

            Hello World
            -----BEGIN PGP SIGNATURE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            iD8DBQFDz7DiRrtV8IhcZaQRAjuYAJ43/NhhNHx+gzGBUqtIK5LpENTCGgCfV3aO
            ZTFlGRyKN26HccsC6ZWcPUQ=
            =kZ2c
            -----END PGP SIGNATURE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        sigs = ctx.verify(signature, None, plaintext)

        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].notations, [])
        self.assertEqual(sigs[0].timestamp, 1137684706)
        self.assertEqual(sigs[0].exp_timestamp, 0)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_verify_multiple_sigs(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP SIGNED MESSAGE-----
            Hash: SHA1

            Hello World
            -----BEGIN PGP SIGNATURE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            iD8DBQFDz7V9RrtV8IhcZaQRAia/AJ9eC/Q3pssWW9PWckQ3+1kbiIiEVQCfSeFv
            7SlUCFJOs/sfl+EtaOafgQGJAhUDBQFDz7V9LPRrf8l+aw8BAia/EAClI1X/hL38
            6NeOnMD6zXNm7r20Qkpp7PT63PqUa9dU1P+Ha2Uju5C2jBVYouDOpHnEsw3AqItl
            M0y6xiBAbXbdv0K2OdX8/290g/uODQE/oRGu+YtIh8HcY9N1JmzYw6msRO1LD/Oo
            xVqfyJiPx+Ol3juAuVqggBzQQmhQpZ7MfHcZSIWxYtRZNlCGYp2lUVae7fJlrJc8
            DvTkGSkdqBRoDqy0rKcdXRuExXyq081m7bli2sMvImejmEsqyMcbZrkW69v+/BQD
            Tki8tEkxINw1YHhcBDI0KAn3SuynY+i132oU2qJWQF3ZBRqEbD0IxfakPSZyhJKj
            sxk38VHgA+5r/QKRs+4n3z09yFqNIWpnvVVZ2iMfKhHtKd1nNq6tOzHiQrmdSdyK
            dwRaRm4Zt0hWT8v+CXX/RPK5xGL3FCZQs7VTO0ANHR7cIS+v3ChaHO6naQSBQMrW
            7l69hTh009LFIKlYJ+7ZBS2pySkvHmEzJKl4Ko4UfOeD2xDsq5nHhi/AJ7TXtHCo
            TLo8OwJvfiW6Fa9zzu6IkerhQlZrvbLOkmBpuyFo0UEuM/89bquaZ3GoEj3hePsZ
            nD9LtsgsjkFV1jZQ4n/wM3jolo0aA4+ZEBCgw9XJUSZ67m+jvFNBvZtDqWnbQWxe
            FsW3EQWNlQnwkn2lic51Cdp3w7yPH5CKfw==
            =0A7N
            -----END PGP SIGNATURE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        sigs = ctx.verify(signature, None, plaintext)

        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 2)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].notations, [])
        self.assertEqual(sigs[0].timestamp, 1137685885)
        self.assertEqual(sigs[0].exp_timestamp, 0)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

        self.assertEqual(sigs[1].summary, 0)
        self.assertEqual(sigs[1].fpr,
                         '93C2240D6B8AA10AB28F701D2CF46B7FC97E6B0F')
        self.assertEqual(sigs[1].status, None)
        self.assertEqual(sigs[1].notations, [])
        self.assertEqual(sigs[1].timestamp, 1137685885)
        self.assertEqual(sigs[1].exp_timestamp, 0)
        self.assertEqual(sigs[1].wrong_key_usage, False)
        self.assertEqual(sigs[1].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[1].validity_reason, None)

    def test_verify_no_signature(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP SIGNED MESSAGE-----
            Hash: SHA1

            Hello World
            -----BEGIN PGP SIGNATURE-----
            -----END PGP SIGNATURE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        sigs = ctx.verify(signature, None, plaintext)

        self.assertEqual(plaintext.getvalue(), b'')
        self.assertEqual(len(sigs), 0)

    def test_verify_bad_signature(self):
        signature = BytesIO(dedent('''
            -----BEGIN PGP SIGNED MESSAGE-----
            Hash: SHA1

            Hello World
            -----BEGIN PGP SIGNATURE-----
            Version: GnuPG v1.4.1 (GNU/Linux)

            iNhhNHx+gzGBUqtIK5LpENTCGgCfV3aO
            -----END PGP SIGNATURE-----
            ''').encode('ASCII'))
        plaintext = BytesIO()
        ctx = gpgme.Context()
        try:
            ctx.verify(signature, None, plaintext)
        except gpgme.GpgmeError as exc:
            self.assertEqual(exc.args[0], gpgme.ERR_SOURCE_GPGME)
            self.assertEqual(exc.args[1], gpgme.ERR_NO_DATA)
        else:
            self.fail('gpgme.GpgmeError not raised')

    def test_sign_normal(self):
        ctx = gpgme.Context()
        ctx.armor = False
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.signers = [key]
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_NORMAL)
        self.assertEqual(len(new_sigs), 1)
        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_NORMAL)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # now verify the signature
        signature.seek(0)
        plaintext = BytesIO()
        sigs = ctx.verify(signature, None, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_sign_normal_armor(self):
        ctx = gpgme.Context()
        ctx.armor = True
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.signers = [key]
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_NORMAL)
        self.assertEqual(len(new_sigs), 1)
        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_NORMAL)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # now verify the signature
        signature.seek(0)
        plaintext = BytesIO()
        sigs = ctx.verify(signature, None, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_sign_detatch(self):
        ctx = gpgme.Context()
        ctx.armor = True
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.signers = [key]
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_DETACH)
        self.assertEqual(len(new_sigs), 1)
        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_DETACH)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # now verify the signature
        signature.seek(0)
        plaintext.seek(0)
        sigs = ctx.verify(signature, plaintext, None)
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

    def test_sign_clearsign(self):
        ctx = gpgme.Context()
        ctx.armor = True
        key = ctx.get_key('E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        ctx.signers = [key]
        plaintext = BytesIO(b'Hello World\n')
        signature = BytesIO()

        new_sigs = ctx.sign(plaintext, signature, gpgme.SIG_MODE_CLEAR)
        self.assertEqual(len(new_sigs), 1)
        self.assertEqual(new_sigs[0].type, gpgme.SIG_MODE_CLEAR)
        self.assertEqual(new_sigs[0].fpr,
                        'E79A842DA34A1CA383F64A1546BB55F0885C65A4')

        # now verify the signature
        signature.seek(0)
        plaintext = BytesIO()
        sigs = ctx.verify(signature, None, plaintext)
        self.assertEqual(plaintext.getvalue(), b'Hello World\n')
        self.assertEqual(len(sigs), 1)
        self.assertEqual(sigs[0].summary, 0)
        self.assertEqual(sigs[0].fpr,
                         'E79A842DA34A1CA383F64A1546BB55F0885C65A4')
        self.assertEqual(sigs[0].status, None)
        self.assertEqual(sigs[0].wrong_key_usage, False)
        self.assertEqual(sigs[0].validity, gpgme.VALIDITY_UNKNOWN)
        self.assertEqual(sigs[0].validity_reason, None)

def test_suite():
    loader = unittest.TestLoader()
    return loader.loadTestsFromName(__name__)

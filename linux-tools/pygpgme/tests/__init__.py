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

def test_suite():
    import tests.test_context
    import tests.test_keys
    import tests.test_keylist
    import tests.test_import
    import tests.test_export
    import tests.test_delete
    import tests.test_sign_verify
#    import tests.test_encrypt_decrypt
#    import tests.test_passphrase
    import tests.test_progress
    import tests.test_editkey
    import tests.test_genkey

    suite = unittest.TestSuite()

    suite.addTest(tests.test_context.test_suite())
    suite.addTest(tests.test_keys.test_suite())
    suite.addTest(tests.test_keylist.test_suite())
    suite.addTest(tests.test_import.test_suite())
    suite.addTest(tests.test_export.test_suite())
    suite.addTest(tests.test_delete.test_suite())
    suite.addTest(tests.test_sign_verify.test_suite())
#    suite.addTest(tests.test_encrypt_decrypt.test_suite())
#    suite.addTest(tests.test_passphrase.test_suite())
    suite.addTest(tests.test_progress.test_suite())
    suite.addTest(tests.test_editkey.test_suite())
    suite.addTest(tests.test_genkey.test_suite())

    return suite

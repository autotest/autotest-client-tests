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
import shutil
import tempfile
import unittest

import gpgme

__all__ = ['GpgHomeTestCase']

keydir = os.path.join(os.path.dirname(__file__), 'keys')

class GpgHomeTestCase(unittest.TestCase):

    gpg_conf_contents = ''
    import_keys = []

    def keyfile(self, key):
        return open(os.path.join(keydir, key), 'rb')

    def setUp(self):
        self._gpghome = tempfile.mkdtemp(prefix='tmp.gpghome')
        os.environ['GNUPGHOME'] = self._gpghome
        fp = open(os.path.join(self._gpghome, 'gpg.conf'), 'wb')
        fp.write(self.gpg_conf_contents.encode('UTF-8'))
        fp.close()

        # import requested keys into the keyring
        ctx = gpgme.Context()
        for key in self.import_keys:
            with self.keyfile(key) as fp:
                ctx.import_(fp)

    def tearDown(self):
        del os.environ['GNUPGHOME']
        shutil.rmtree(self._gpghome, ignore_errors=True)

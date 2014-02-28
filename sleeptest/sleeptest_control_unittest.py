#!/usr/bin/env python

#  Copyright(c) 2014 Intel Corporation.
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms and conditions of the GNU General Public License,
#  version 2, as published by the Free Software Foundation.
#
#  This program is distributed in the hope it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
#
#  The full GNU General Public License is included in this distribution in
#  the file called "COPYING".


import os
import __builtin__

import unittest

try:
    import autotest.common as common
except ImportError:
    import common

from autotest.client.shared.mock import patch, MagicMock, call
from autotest.client.shared.file_module_loader import load_module_from_file


job_mock = MagicMock()
_p = patch.object(__builtin__, "job", job_mock, create=True)
_p.start()
try:
    sut_setup_control = load_module_from_file(
        os.path.join(os.path.dirname(__file__), "control"))
finally:
    _p.stop()


class TestSleeptestControl(unittest.TestCase):

    @staticmethod
    def test_sleeptest_control():
        assert "autotest" in sut_setup_control.DOC
        assert job_mock.run_test.call_args_list == [
            call("sleeptest", seconds=1)]

if __name__ == '__main__':
    unittest.main()

#!/usr/bin/env python

import sys
import tests

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '-g':
        import unittestgui
        unittestgui.main('tests.suite')
    else:
        import unittest
        unittest.main(defaultTest='tests.suite')

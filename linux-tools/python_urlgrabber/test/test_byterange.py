#!/usr/bin/python -t

#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the 
#      Free Software Foundation, Inc., 
#      59 Temple Place, Suite 330, 
#      Boston, MA  02111-1307  USA

# This file is part of urlgrabber, a high-level cross-protocol url-grabber
# Copyright 2002-2004 Michael D. Stenner, Ryan Tomayko

"""byterange.py tests"""

# $Id: test_byterange.py,v 1.6 2004/03/31 17:02:00 mstenner Exp $

import sys

from cStringIO import StringIO
from urlgrabber.byterange import RangeableFileObject

from base_test_code import *

class RangeableFileObjectTestCase(TestCase):
    """Test range.RangeableFileObject class"""
    
    def setUp(self):
        #            0         1         2         3         4         5          6         7         8         9
        #            0123456789012345678901234567890123456789012345678901234567 890123456789012345678901234567890
        self.test = 'Why cannot we write the entire 24 volumes of Encyclopaedia\nBrittanica on the head of a pin?\n'
        self.fo = StringIO(self.test)
        self.rfo = RangeableFileObject(self.fo, (20,69))
        
    def tearDown(self):
        pass
    
    def test_seek(self):
        """RangeableFileObject.seek()"""
        self.rfo.seek(11)
        self.assertEquals('24', self.rfo.read(2))
        self.rfo.seek(14)
        self.assertEquals('volumes', self.rfo.read(7))
        self.rfo.seek(1,1)
        self.assertEquals('of', self.rfo.read(2))
    
    def test_read(self):
        """RangeableFileObject.read()"""
        self.assertEquals('the', self.rfo.read(3))
        self.assertEquals(' entire 24 volumes of ', self.rfo.read(22))
        self.assertEquals('Encyclopaedia\nBrittanica', self.rfo.read(50))
        self.assertEquals('', self.rfo.read())
    
    def test_readall(self):
        """RangeableFileObject.read(): to end of file."""
        rfo = RangeableFileObject(StringIO(self.test),(11,))
        self.assertEquals(self.test[11:],rfo.read())
        
    def test_readline(self):
        """RangeableFileObject.readline()"""
        self.assertEquals('the entire 24 volumes of Encyclopaedia\n', self.rfo.readline())
        self.assertEquals('Brittanica', self.rfo.readline())
        self.assertEquals('', self.rfo.readline())
    
    def test_tell(self):
        """RangeableFileObject.tell()"""
        self.assertEquals(0,self.rfo.tell())
        self.rfo.read(5)
        self.assertEquals(5,self.rfo.tell())
        self.rfo.readline()
        self.assertEquals(39,self.rfo.tell())
        
class RangeModuleTestCase(TestCase):
    """Test module level functions defined in range.py"""
    def setUp(self):
        pass
        
    def tearDown(self):
        pass
    
    def test_range_tuple_normalize(self):
        """byterange.range_tuple_normalize()"""
        from urlgrabber.byterange import range_tuple_normalize
        from urlgrabber.byterange import RangeError
        tests = ( 
                    ((None,50), (0,50)),
                    ((500,600), (500,600)),
                    ((500,), (500,'')),
                    ((500,None), (500,'')),
                    (('',''), None),
                    ((0,), None),
                    (None, None)
                 )
        for test, ex in tests:
            self.assertEquals( range_tuple_normalize(test), ex )
        
        try: range_tuple_normalize( (10,8) )
        except RangeError: pass
        else: self.fail("range_tuple_normalize( (10,8) ) should have raised RangeError")
        
    def test_range_header_to_tuple(self):
        """byterange.range_header_to_tuple()"""
        from urlgrabber.byterange import range_header_to_tuple
        tests = ( 
                    ('bytes=500-600', (500,601)),
                    ('bytes=500-', (500,'')),
                    ('bla bla', ()),
                    (None, None)
                 )
        for test, ex in tests:
            self.assertEquals( range_header_to_tuple(test), ex )
    
    def test_range_tuple_to_header(self):
        """byterange.range_tuple_to_header()"""
        from urlgrabber.byterange import range_tuple_to_header
        tests = ( 
                    ((500,600), 'bytes=500-599'),
                    ((500,''), 'bytes=500-'),
                    ((500,), 'bytes=500-'),
                    ((None,500), 'bytes=0-499'),
                    (('',500), 'bytes=0-499'),
                    (None, None),
                 )
        for test, ex in tests:
            self.assertEquals( range_tuple_to_header(test), ex )
        
        try: range_tuple_to_header( ('not an int',500) )
        except ValueError: pass
        else: self.fail("range_tuple_to_header( ('not an int',500) ) should have raised ValueError")
        
        try: range_tuple_to_header( (0,'not an int') )
        except ValueError: pass
        else: self.fail("range_tuple_to_header( (0, 'not an int') ) should have raised ValueError")
                
def suite():
    tl = TestLoader()
    return tl.loadTestsFromModule(sys.modules[__name__])

if __name__ == '__main__':
    runner = TextTestRunner(stream=sys.stdout,descriptions=1,verbosity=2)
    runner.run(suite())


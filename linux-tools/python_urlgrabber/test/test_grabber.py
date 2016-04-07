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

"""grabber.py tests"""

# $Id: test_grabber.py,v 1.31 2006/12/08 00:14:16 mstenner Exp $

import sys
import os
import string, tempfile, random, cStringIO, os
import urllib2
import socket

from base_test_code import *

import urlgrabber
import urlgrabber.grabber as grabber
from urlgrabber.grabber import URLGrabber, URLGrabError, CallbackObject, \
     URLParser
from urlgrabber.progress import text_progress_meter

class FileObjectTests(TestCase):
    
    def setUp(self):
        self.filename = tempfile.mktemp()
        fo = file(self.filename, 'wb')
        fo.write(reference_data)
        fo.close()

        self.fo_input = cStringIO.StringIO(reference_data)
        self.fo_output = cStringIO.StringIO()
        (url, parts) = grabber.default_grabber.opts.urlparser.parse(
            self.filename, grabber.default_grabber.opts)
        self.wrapper = grabber.PyCurlFileObject(
            url, self.fo_output, grabber.default_grabber.opts)

    def tearDown(self):
        self.wrapper.close()
        os.unlink(self.filename)

    def test_readall(self):
        "PYCurlFileObject .read() method"
        s = self.wrapper.read()
        self.fo_output.write(s)
        self.assert_(reference_data == self.fo_output.getvalue())

    def test_readline(self):
        "PyCurlFileObject .readline() method"
        while 1:
            s = self.wrapper.readline()
            self.fo_output.write(s)
            if not s: break
        self.assert_(reference_data == self.fo_output.getvalue())

    def test_readlines(self):
        "PyCurlFileObject .readlines() method"
        li = self.wrapper.readlines()
        self.fo_output.write(string.join(li, ''))
        self.assert_(reference_data == self.fo_output.getvalue())

    def test_smallread(self):
        "PyCurlFileObject .read(N) with small N"
        while 1:
            s = self.wrapper.read(23)
            self.fo_output.write(s)
            if not s: break
        self.assert_(reference_data == self.fo_output.getvalue())
    
class HTTPTests(TestCase):
    def test_reference_file(self):
        "download reference file via HTTP"
        filename = tempfile.mktemp()
        grabber.urlgrab(ref_http, filename)

        fo = file(filename, 'rb')
        contents = fo.read()
        fo.close()

        self.assert_(contents == reference_data)

    def test_post(self):
        "do an HTTP post"
        self.skip() # disabled on server
        headers = (('Content-type', 'text/plain'),)
        ret = grabber.urlread(base_http + 'test_post.php',
                              data=short_reference_data,
                              http_headers=headers)

        self.assertEqual(ret, short_reference_data)

class URLGrabberModuleTestCase(TestCase):
    """Test module level functions defined in grabber.py"""
    def setUp(self):
        pass
        
    def tearDown(self):
        pass
    
    def test_urlopen(self):
        "module-level urlopen() function"
        fo = urlgrabber.urlopen('http://abat.au.example.com')
        fo.close()
    
    def test_urlgrab(self):
        "module-level urlgrab() function"
        outfile = tempfile.mktemp()
        filename = urlgrabber.urlgrab('http://abat.au.example.com', 
                                    filename=outfile)
        os.unlink(outfile)
    
    def test_urlread(self):
        "module-level urlread() function"
        s = urlgrabber.urlread('http://abat.au.example.com')

       
class URLGrabberTestCase(TestCase):
    """Test grabber.URLGrabber class"""
    
    def setUp(self):
        
        self.meter = text_progress_meter( fo=cStringIO.StringIO() )
        pass
    
    def tearDown(self):
        pass
    
    def testKeywordArgs(self):
        """grabber.URLGrabber.__init__() **kwargs handling.
        
        This is a simple test that just passes some arbitrary
        values into the URLGrabber constructor and checks that
        they've been set properly.
        """
        opener = urllib2.OpenerDirector()
        g = URLGrabber( progress_obj=self.meter,
                        throttle=0.9,
                        bandwidth=20,
                        retry=20,
                        retrycodes=[5,6,7],
                        copy_local=1,
                        close_connection=1,
                        user_agent='test ua/1.0',
                        proxies={'http' : 'http://www.proxy.com:9090'},
                        opener=opener )
        opts = g.opts
        self.assertEquals( opts.progress_obj, self.meter )
        self.assertEquals( opts.throttle, 0.9 )
        self.assertEquals( opts.bandwidth, 20 )
        self.assertEquals( opts.retry, 20 )
        self.assertEquals( opts.retrycodes, [5,6,7] )
        self.assertEquals( opts.copy_local, 1 )
        self.assertEquals( opts.close_connection, 1 )
        self.assertEquals( opts.user_agent, 'test ua/1.0' )
        self.assertEquals( opts.proxies, {'http' : 'http://www.proxy.com:9090'} )
        self.assertEquals( opts.opener, opener )
        
        nopts = grabber.URLGrabberOptions(delegate=opts, throttle=0.5, 
                                        copy_local=0)
        self.assertEquals( nopts.progress_obj, self.meter )
        self.assertEquals( nopts.throttle, 0.5 )
        self.assertEquals( nopts.bandwidth, 20 )
        self.assertEquals( nopts.retry, 20 )
        self.assertEquals( nopts.retrycodes, [5,6,7] )
        self.assertEquals( nopts.copy_local, 0 )
        self.assertEquals( nopts.close_connection, 1 )
        self.assertEquals( nopts.user_agent, 'test ua/1.0' )
        self.assertEquals( nopts.proxies, {'http' : 'http://www.proxy.com:9090'} )
        nopts.opener = None
        self.assertEquals( nopts.opener, None )
        
    def test_make_callback(self):
        """grabber.URLGrabber._make_callback() tests"""
        def cb(e): pass
        tup_cb = (cb, ('stuff'), {'some': 'dict'})
        g = URLGrabber()
        self.assertEquals(g._make_callback(cb),     (cb, (), {}))
        self.assertEquals(g._make_callback(tup_cb), tup_cb)

class URLParserTestCase(TestCase):
    def setUp(self):
        pass
    
    def tearDown(self):
        pass

    def test_parse_url_with_prefix(self):
        """grabber.URLParser.parse() with opts.prefix"""
        base = 'http://foo.com/dir'
        bases = [base, base+'/']
        filename = 'bar/baz'
        target = base + '/' + filename
        
        for b in bases:
            g = URLGrabber(prefix=b)
            (url, parts) = g.opts.urlparser.parse(filename, g.opts)
            self.assertEquals(url, target)

    def _test_url(self, urllist):
        g = URLGrabber()
        try: quote = urllist[3]
        except IndexError: quote = None
        g.opts.quote = quote
        (url, parts) = g.opts.urlparser.parse(urllist[0], g.opts)
        
        if 1:
            self.assertEquals(url, urllist[1])
            self.assertEquals(parts, urllist[2])
        else:
            if url == urllist[1] and parts == urllist[2]:
                print 'OK: %s' % urllist[0]
            else:
                print 'ERROR: %s' % urllist[0]
                print '  ' + urllist[1]
                print '  ' + url
                print '  ' + urllist[2]
                print '  ' + parts
                

    url_tests_all = (
        ['http://host.com/path/basename.ext?arg1=val1&arg2=val2#hash',
         'http://host.com/path/basename.ext?arg1=val1&arg2=val2#hash',
         ('http', 'host.com', '/path/basename.ext', '',
          'arg1=val1&arg2=val2', 'hash')],
        ['http://host.com/Path With Spaces/',
         'http://host.com/Path%20With%20Spaces/',
         ('http', 'host.com', '/Path%20With%20Spaces/', '', '', '')],
        ['http://host.com/Already%20Quoted',
         'http://host.com/Already%20Quoted',
         ('http', 'host.com', '/Already%20Quoted', '', '', '')],
        ['http://host.com/Should Be Quoted',
         'http://host.com/Should Be Quoted',
         ('http', 'host.com', '/Should Be Quoted', '', '', ''), 0],
        ['http://host.com/Should%20Not',
         'http://host.com/Should%2520Not',
         ('http', 'host.com', '/Should%2520Not', '', '', ''), 1],
        )
        
    url_tests_posix = (
        ['/etc/passwd',
         'file:///etc/passwd',
         ('file', '', '/etc/passwd', '', '', '')],
        )
    
    url_tests_nt = (
        [r'\\foo.com\path\file.ext',
         'file://foo.com/path/file.ext',
         ('file', '', '//foo.com/path/file.ext', '', '', '')],
        [r'C:\path\file.ext',
         'file:///C|/path/file.ext',
         ('file', '', '/C|/path/file.ext', '', '', '')],
        )

    def test_url_parser_all_os(self):
        """test url parsing common to all OSs"""
        for f in self.url_tests_all:
            self._test_url(f)

    def test_url_parser_posix(self):
        """test url parsing on posix systems"""
        if not os.name == 'posix':
            self.skip()
        for f in self.url_tests_posix:
            self._test_url(f)

    def test_url_parser_nt(self):
        """test url parsing on windows systems"""
        if not os.name == 'nt':
            self.skip()
        for f in self.url_tests_nt:
            self._test_url(f)


class FailureTestCase(TestCase):
    """Test failure behavior"""

    def _failure_callback(self, obj, *args, **kwargs):
        self.failure_callback_called = 1
        self.obj = obj
        self.args = args
        self.kwargs = kwargs
        
    def test_failure_callback_called(self):
        "failure callback is called on retry"
        self.failure_callback_called = 0
        g = grabber.URLGrabber(retry=2, retrycodes=[14],
                               failure_callback=self._failure_callback)
        try: g.urlgrab(ref_404)
        except URLGrabError: pass
        self.assertEquals(self.failure_callback_called, 1)

    def test_failure_callback_args(self):
        "failure callback is called with the proper args"
        fc = (self._failure_callback, ('foo',), {'bar': 'baz'})
        g = grabber.URLGrabber(retry=2, retrycodes=[14],
                               failure_callback=fc)
        try: g.urlgrab(ref_404)
        except URLGrabError: pass
        self.assert_(hasattr(self, 'obj'))
        self.assert_(hasattr(self, 'args'))
        self.assert_(hasattr(self, 'kwargs'))
        self.assertEquals(self.args, ('foo',))
        self.assertEquals(self.kwargs, {'bar': 'baz'})
        self.assert_(isinstance(self.obj, CallbackObject))
        self.assertEquals(self.obj.url, ref_404)
        self.assert_(isinstance(self.obj.exception, URLGrabError))
        del self.obj

class InterruptTestCase(TestCase):
    """Test interrupt callback behavior"""

    class InterruptProgress:
        def start(self, *args, **kwargs): pass
        def update(self, *args, **kwargs): raise KeyboardInterrupt
        def end(self, *args, **kwargs): pass

    class TestException(Exception): pass

    def _interrupt_callback(self, obj, *args, **kwargs):
        self.interrupt_callback_called = 1
        self.obj = obj
        self.args = args
        self.kwargs = kwargs
        if kwargs.get('exception', None):
            raise kwargs['exception']
        
    def test_interrupt_callback_called(self):
        "interrupt callback is called on retry"
	print >> sys.stderr, 'interrupt callback tests start' 
        self.interrupt_callback_called = 0
        ic = (self._interrupt_callback, (), {})
        g = grabber.URLGrabber(progress_obj=self.InterruptProgress(),
                               interrupt_callback=ic)
        try: g.urlgrab(ref_http)
        except KeyboardInterrupt: pass
        self.assertEquals(self.interrupt_callback_called, 1)

    def test_interrupt_callback_raises(self):
        "interrupt callback raises an exception"
        ic = (self._interrupt_callback, (),
              {'exception': self.TestException()})
        g = grabber.URLGrabber(progress_obj=self.InterruptProgress(),
                               interrupt_callback=ic)
        self.assertRaises(self.TestException, g.urlgrab, ref_http)
	print >> sys.stderr, 'interrupt callback tests end' 	

class CheckfuncTestCase(TestCase):
    """Test checkfunc behavior"""

    def setUp(self):
        cf = (self._checkfunc, ('foo',), {'bar': 'baz'})
        self.g = grabber.URLGrabber(checkfunc=cf)
        self.filename = tempfile.mktemp()
        self.data = short_reference_data
        
    def tearDown(self):
        try: os.unlink(self.filename)
        except: pass
        if hasattr(self, 'obj'): del self.obj
        
    def _checkfunc(self, obj, *args, **kwargs):
        self.obj = obj
        self.args = args
        self.kwargs = kwargs

        if hasattr(obj, 'filename'):
            # we used urlgrab
            fo = file(obj.filename)
            data = fo.read()
            fo.close()
        else:
            # we used urlread
            data = obj.data

        if data == self.data: return
        else: raise URLGrabError(-2, "data doesn't match")
        
    def _check_common_args(self):
        "check the args that are common to both urlgrab and urlread"
        self.assert_(hasattr(self, 'obj'))
        self.assert_(hasattr(self, 'args'))
        self.assert_(hasattr(self, 'kwargs'))
        self.assertEquals(self.args, ('foo',))
        self.assertEquals(self.kwargs, {'bar': 'baz'})
        self.assert_(isinstance(self.obj, CallbackObject))
        self.assertEquals(self.obj.url, short_ref_http)

    def test_checkfunc_urlgrab_args(self):
        "check for proper args when used with urlgrab"
        self.g.urlgrab(short_ref_http, self.filename)
        self._check_common_args()
        self.assertEquals(self.obj.filename, self.filename)

    def test_checkfunc_urlread_args(self):
        "check for proper args when used with urlread"
        self.g.urlread(short_ref_http)
        self._check_common_args()
        self.assertEquals(self.obj.data, short_reference_data)

    def test_checkfunc_urlgrab_success(self):
        "check success with urlgrab checkfunc"
        self.data = short_reference_data
        self.g.urlgrab(short_ref_http, self.filename)

    def test_checkfunc_urlread_success(self):
        "check success with urlread checkfunc"
        self.data = short_reference_data
        self.g.urlread(short_ref_http)

    def test_checkfunc_urlgrab_failure(self):
        "check failure with urlgrab checkfunc"
        self.data = 'other data'
        self.assertRaises(URLGrabError, self.g.urlgrab,
                          short_ref_http, self.filename)

    def test_checkfunc_urlread_failure(self):
        "check failure with urlread checkfunc"
        self.data = 'other data'
        self.assertRaises(URLGrabError, self.g.urlread,
                          short_ref_http)

class RegetTestBase:
    def setUp(self):
        self.ref = short_reference_data
        self.grabber = grabber.URLGrabber(reget='check_timestamp')
        self.filename = tempfile.mktemp()
        self.hl = len(self.ref) / 2
        self.url = 'OVERRIDE THIS'

    def tearDown(self):
        try: os.unlink(self.filename)
        except: pass

    def _make_half_zero_file(self):
        fo = file(self.filename, 'wb')
        fo.write('0'*self.hl)
        fo.close()

    def _read_file(self):
        fo = file(self.filename, 'rb')
        data = fo.read()
        fo.close()
        return data
    
class CommonRegetTests(RegetTestBase, TestCase):
    def test_bad_reget_type(self):
        "exception raised for illegal reget mode"
        self.assertRaises(URLGrabError, self.grabber.urlgrab,
                          self.url, self.filename, reget='junk')

class FTPRegetTests(RegetTestBase, TestCase):
    def setUp(self):
        RegetTestBase.setUp(self)
        self.url = short_ref_ftp
        # this tests to see if the server is available.  If it's not,
        # then these tests will be skipped
        try:
            fo = urllib2.urlopen(self.url).close()
        except IOError:
            self.skip()

    def test_basic_reget(self):
        'simple (forced) reget'
        self._make_half_zero_file()
        self.grabber.urlgrab(self.url, self.filename, reget='simple')
        data = self._read_file()

        self.assertEquals(data[:self.hl], '0'*self.hl)
        self.assertEquals(data[self.hl:], self.ref[self.hl:])

class HTTPRegetTests(FTPRegetTests):
    def setUp(self):
        RegetTestBase.setUp(self)
        self.url = short_ref_http
        
    def test_older_check_timestamp(self):
        try:
            # define this here rather than in the FTP tests because currently,
            # we get no timestamp information back from ftp servers.
            self._make_half_zero_file()
            ts = 1600000000 # set local timestamp to 2020
            os.utime(self.filename, (ts, ts)) 
            self.grabber.urlgrab(self.url, self.filename, reget='check_timestamp')
            data = self._read_file()

            self.assertEquals(data[:self.hl], '0'*self.hl)
            self.assertEquals(data[self.hl:], self.ref[self.hl:])
        except NotImplementedError:
            self.skip()
            
    def test_newer_check_timestamp(self):
        try:
            # define this here rather than in the FTP tests because currently,
            # we get no timestamp information back from ftp servers.
            self._make_half_zero_file()
            ts = 1 # set local timestamp to 1969
            os.utime(self.filename, (ts, ts)) 
            self.grabber.urlgrab(self.url, self.filename, reget='check_timestamp')
            data = self._read_file()

            self.assertEquals(data, self.ref)
        except:
            self.skip()
            
class FileRegetTests(HTTPRegetTests):
    def setUp(self):
        self.ref = short_reference_data
        tmp = tempfile.mktemp()
        tmpfo = file(tmp, 'wb')
        tmpfo.write(self.ref)
        tmpfo.close()
        self.tmp = tmp
        
        (url, parts) = grabber.default_grabber.opts.urlparser.parse(
            tmp, grabber.default_grabber.opts)
        self.url = url

        self.grabber = grabber.URLGrabber(reget='check_timestamp',
                                          copy_local=1)
        self.filename = tempfile.mktemp()
        self.hl = len(self.ref) / 2

    def tearDown(self):
        try: os.unlink(self.filename)
        except: pass
        try: os.unlink(self.tmp)
        except: pass

class ProFTPDSucksTests(TestCase):
    def setUp(self):
        self.url = ref_proftp
        try:
            fo = urllib2.urlopen(self.url).close()
        except IOError:
            self.skip()

    def test_restart_workaround(self):
        inst = grabber.URLGrabber()
        rslt = inst.urlread(self.url, range=(500, 1000))
        
class BaseProxyTests(TestCase):
    good_p = '%s://%s:%s@%s:%i' % (proxy_proto, proxy_user,
                                   good_proxy_pass, proxy_host, proxy_port)
    bad_p = '%s://%s:%s@%s:%i' % (proxy_proto, proxy_user,
                                  bad_proxy_pass, proxy_host, proxy_port)
    good_proxies = {'ftp': good_p, 'http': good_p}
    bad_proxies =  {'ftp': bad_p,  'http': bad_p}

    def have_proxy(self):
        have_proxy = 1
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            s.connect((proxy_host, proxy_port))
            s.close()
        except socket.error:
            have_proxy = 0
        return have_proxy


class ProxyHTTPAuthTests(BaseProxyTests):
    def setUp(self):
        self.url = ref_http
        if not self.have_proxy():
            self.skip()
        self.g = URLGrabber()

    def test_good_password(self):
        self.g.urlopen(self.url, proxies=self.good_proxies)

    def test_bad_password(self):
        self.assertRaises(URLGrabError, self.g.urlopen,
                          self.url, proxies=self.bad_proxies)

class ProxyFTPAuthTests(ProxyHTTPAuthTests):
    def setUp(self):
        self.url = ref_ftp
        if not self.have_proxy():
            self.skip()
        try:
            fo = urllib2.urlopen(self.url).close()
        except IOError:
            self.skip()
        self.g = URLGrabber()

def suite():
    tl = TestLoader()
    return tl.loadTestsFromModule(sys.modules[__name__])

if __name__ == '__main__':
    grabber.DEBUG = 0
    runner = TextTestRunner(stream=sys.stdout,descriptions=1,verbosity=2)
    runner.run(suite())
     

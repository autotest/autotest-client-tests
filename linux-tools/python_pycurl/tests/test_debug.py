#! /usr/bin/env python
# -*- coding: iso-8859-1 -*-
# vi:ts=4:et
# $Id: test_debug.py,v 1.6 2003/04/21 18:46:10 mfx Exp $

import pycurl

def test(t, b):
    print "debug(%d): %s" % (t, b)

c = pycurl.Curl()
c.setopt(pycurl.URL, 'http://curl.haxx.se/')
c.setopt(pycurl.VERBOSE, 1)
c.setopt(pycurl.DEBUGFUNCTION, test)
c.perform()
c.close()

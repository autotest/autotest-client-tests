#! /usr/bin/env python
# -*- coding: iso-8859-1 -*-
# vi:ts=4:et
# $Id: test_stringio.py,v 1.6 2003/04/21 18:46:11 mfx Exp $

import sys
try:
    from cStringIO import StringIO
except ImportError:
    from StringIO import StringIO
import pycurl

url = "http://curl.haxx.se/dev/"

print "Testing", pycurl.version

body = StringIO()
c = pycurl.Curl()
c.setopt(c.URL, url)
c.setopt(c.WRITEFUNCTION, body.write)
c.perform()
c.close()

contents = body.getvalue()
print contents

#! /usr/bin/env python
# -*- coding: iso-8859-1 -*-
# vi:ts=4:et
# $Id: test_multi5.py,v 1.12 2005/03/11 13:24:45 kjetilja Exp $

import pycurl

c1 = pycurl.Curl()
c2 = pycurl.Curl()
c3 = pycurl.Curl()
c1.setopt(c1.URL, "localhost/README.html")
c2.setopt(c2.URL, "http://localhost/python-pycurl/learnHTML.html")
c3.setopt(c3.URL, "http://localhost/python-pycurl/cag.html")
c1.body = open("doc1", "wb")
c2.body = open("doc2", "wb")
c3.body = open("doc3", "wb")
c1.setopt(c1.WRITEFUNCTION, c1.body.write)
c2.setopt(c2.WRITEFUNCTION, c2.body.write)
c3.setopt(c3.WRITEFUNCTION, c3.body.write)

m = pycurl.CurlMulti()
m.add_handle(c1)
m.add_handle(c2)
m.add_handle(c3)

# Number of seconds to wait for a timeout to happen
SELECT_TIMEOUT = 1.0

# Stir the state machine into action
while 1:
    ret, num_handles = m.perform()
    if ret != pycurl.E_CALL_MULTI_PERFORM:
        break

# Keep going until all the connections have terminated
while num_handles:
    # The select method uses fdset internally to determine which file descriptors
    # to check.
    m.select(SELECT_TIMEOUT)
    while 1:
        ret, num_handles = m.perform()
        if ret != pycurl.E_CALL_MULTI_PERFORM:
            break

# Cleanup
m.remove_handle(c3)
m.remove_handle(c2)
m.remove_handle(c1)
m.close()
c1.body.close()
c2.body.close()
c3.body.close()
c1.close()
c2.close()
c3.close()
print "localhost/README.html is in file doc1"
print "http://localhost/python-pycurl/learnHTML.html is in file doc2"
print "http://localhost/python-pycurl/cag.html is in file doc3"


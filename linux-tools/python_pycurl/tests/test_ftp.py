#! /usr/bin/env python
# -*- coding: iso-8859-1 -*-
# vi:ts=4:et
# $Id: test_ftp.py,v 1.1 2006/08/24 07:36:03 kjetilja Exp $

import pycurl

c = pycurl.Curl()
c.setopt(c.URL, 'ftp://ftp.sunet.se/')
c.setopt(c.FTP_USE_EPSV, 1)
c.setopt(c.QUOTE, ['cwd pub', 'type i'])
c.perform()
c.close()

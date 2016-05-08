"""
ldifwriter - using ldap.async module for output of LDIF stream
             of LDAP search results

Written by Michael Stroeder <michael@stroeder.com>

$Id: ldifwriter.py,v 1.4 2006/03/26 12:23:07 stroeder Exp $

This example translates the naming context of data read from
input, sanitizes some attributes, maps/removes object classes,
maps/removes attributes., etc. It's far from being complete though.

Python compability note:
Tested on Python 2.0+, should run on Python 1.5.x.
"""

import sys,ldap,ldap.async

s = ldap.async.LDIFWriter(
  ldap.initialize('ldap://localhost'),
  sys.stdout
)

s.startSearch(
  'cn=Foo1,dc=python-ldap,dc=org',
  ldap.SCOPE_SUBTREE,
  '(objectClass=*)',
)

try:
  partial = s.processResults()
except ldap.SIZELIMIT_EXCEEDED:
  sys.stderr.write('Warning: Server-side size limit exceeded.\n')
else:
  if partial:
    sys.stderr.write('Warning: Only partial results received.\n')

sys.stderr.write(
  '%d results received.\n' % (
    s.endResultBreak-s.beginResultsDropped
  )
)

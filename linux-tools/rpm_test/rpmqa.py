#!/usr/bin/python
# Acts like rpm -qa and lists the names of all the installed packages.
# Usage:
# python rpmqa.py

import os, rpm
#rpm.addMacro("_dbpath", "/tmp/rpm1")
ts = rpm.TransactionSet()
mi = ts.dbMatch()

for h in mi:
  print "%s-%s-%s" % (h['name'], h['version'], h['release']) 
  if h.dsFromHeader('Providename'):
     print h.dsFromHeader('Providename')
  if h.dsFromHeader('Requirename'):
     print h.dsFromHeader('Requirename')
  if h.dsFromHeader('Obsoletename'):
     print h.dsFromHeader('Obsoletename')
  if h.dsFromHeader('Conflictname'):
     print h.dsFromHeader('Conflictname')

#rpm.delMacro("_dbpath")

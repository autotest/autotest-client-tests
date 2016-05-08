#!/usr/bin/python
# Acts like rpm -q and lists the N-V-R for installed packages
# that match a given name using a glob-like syntax
#
# Usage:
# python rpmglob.py "package_fragment*"

import rpm, sys

ts = rpm.TransactionSet()
mi = ts.dbMatch()
if not mi:
  print "No packages found."
else:
  mi.pattern('name', rpm.RPMMIRE_GLOB, sys.argv[1] )

for h in mi:
  print "%s-%s-%s" % (h['name'], h['version'], h['release']) 


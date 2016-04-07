#!/usr/bin/python
# Lists information on installed package listed on command line.
# Usage:
# python rpminfo.py package_name

import rpm, sys

def printEntry(header, label, format, extra):
  value = header.sprintf(format).strip()
  print "%-20s: %s %s" % (label, value, extra)

def printHeader(h):
  if h[rpm.RPMTAG_SOURCEPACKAGE]:
    extra = " source package"
  else:
    extra = " binary package"

  printEntry(h, 'Package', "%{NAME}-%{VERSION}-%{RELEASE}", extra)
  printEntry(h, 'Group', "%{GROUP}", '')
  printEntry(h, 'Summary', "%{Summary}", '')
  printEntry(h, 'Arch-OS-Platform', "%{ARCH}-%{OS}-%{PLATFORM}", '')
  printEntry(h, 'Vendor', "%{Vendor}", '')
  printEntry(h, 'URL', "%{URL}", '')
  printEntry(h, 'Size', "%{Size}", '')
  printEntry(h, 'Installed on', "%{INSTALLTID:date}", '')
  print h['description']
  print "Files:"
  fi = h.fiFromHeader()
  print fi

# Dependencies
  print "Provides:"
  print h.dsFromHeader('providename')
  print "Requires:"
  print h.dsFromHeader('requirename')
  if h.dsFromHeader('obsoletename'):
    print "Obsoletes:"
    print h.dsFromHeader('obsoletename')
  if h.dsFromHeader('conflictname'):
    print "Conflicts:"
    print h.dsFromHeader('conflictname')

#rpm.addMacro("_dbpath", "/tmp/rpm1") 
ts = rpm.TransactionSet()
mi = ts.dbMatch( 'name', sys.argv[1] )
for h in mi:
  printHeader(h) 
#rpm.delMacro("_dbpath")

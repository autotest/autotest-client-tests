"""
Various examples how to connect to a LDAP host with the new
factory function ldap.initialize() introduced in OpenLDAP 2 API.

Assuming you have LDAP servers running on
ldap://localhost:1390 (LDAP with StartTLS)
ldaps://localhost:1391 (LDAP over SSL)
ldapi://%2ftmp%2fopenldap2 (domain socket /tmp/openldap2)
"""

import sys,os,ldap

# Switch off processing .ldaprc or ldap.conf
os.environ['LDAPNOINIT']='1'

# Set debugging level
#ldap.set_option(ldap.OPT_DEBUG_LEVEL,255)
ldapmodule_trace_level = 1
ldapmodule_trace_file = sys.stderr

ldap._trace_level = ldapmodule_trace_level

# Complete path name of the file containing all trusted CA certs
CACERTFILE='/etc/pki/tls/certs/ca-bundle.crt'

print """##################################################################
# LDAPv3 connection over Unix domain socket
##################################################################
"""

# Create LDAPObject instance
l = ldap.initialize('ldapi://%2ftmp%2fopenldap-socket',trace_level=ldapmodule_trace_level,trace_file=ldapmodule_trace_file)
# Set LDAP protocol version used
l.protocol_version=ldap.VERSION3
# Try an explicit anon bind to provoke failure
l.simple_bind_s('','')
# Close connection
l.unbind_s()

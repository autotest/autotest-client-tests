#!/usr/bin/python

import ldap, ldap.sasl, sys, pprint

try:
        auth = ldap.sasl.gssapi("")
        l = ldap.initialize("ldap://127.0.0.1")
        l.sasl_interactive_bind_s("",auth)
        results = l.search_s( "dc=python-ldap,dc=org", ldap.SCOPE_SUBTREE)
except ldap.LDAPError, error:
        print "LDAP error: %s" % error
        sys.exit()

pp = pprint.PrettyPrinter()
pp.pprint(results)

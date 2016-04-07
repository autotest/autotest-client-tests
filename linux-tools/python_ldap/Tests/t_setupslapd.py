import ldap, unittest
import slapd

from ldap.ldapobject import LDAPObject

server = None

def setup():
	global server
	if server is None:
		server = slapd.Slapd()
		server.start()
	base = server.get_dn_suffix()

	#insert some Foo* objects via ldapadd
	server.ldapadd("\n".join([
	"dn: cn=Foo1,"+base,
	"objectClass: organizationalRole",
	"cn: Foo1",
	"",
	"dn: cn=Foo2,"+base,
	"objectClass: organizationalRole",
	"cn: Foo2",
	"",
	])+"\n")

	l = LDAPObject(server.get_url())
	l.protocol_version = 3
	l.set_option(ldap.OPT_REFERRALS,0)
	l.simple_bind_s(server.get_root_dn(), 
	server.get_root_password())

setup()

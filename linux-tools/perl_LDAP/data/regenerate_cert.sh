#/bin/sh
# regenerate server certificate for the SSL tests

if [ -e openssl.cnf ]; then
	# make sure we have a password-less 2048-bit RSA key
	openssl genrsa -out key.pem 2048 >/dev/null 2>&1

	# create a self-signed certificate with the DN cn=localhost,dc=demo,dc=perl-ldap
	openssl req -config openssl.cnf \
		-new -x509 \
		-key key.pem \
		-out cert.pem \
		-days 365 \
		-subj /domainComponent=perl-ldap/domainComponent=demo/commonName=localhost 
fi

# EOF

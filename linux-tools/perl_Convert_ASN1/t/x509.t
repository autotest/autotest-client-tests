#!/usr/local/bin/perl

print "1..26\n";

BEGIN { require 't/funcs.pl' }

use Convert::ASN1;

my $t = 1;

my $asn = Convert::ASN1->new;
btest $t++, $asn->prepare(<<ASN1);
-- ASN.1 from RFC2459 and X.509(2001)
-- Adapted for use with Convert::ASN1
-- Id: x509decode,v 1.1 2002/02/10 16:41:28 gbarr Exp 

-- attribute data types --

Attribute ::= SEQUENCE {
	type			AttributeType,
	values			SET OF AttributeValue
		-- at least one value is required -- 
	}

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= DirectoryString  --ANY 

AttributeTypeAndValue ::= SEQUENCE {
	type			AttributeType,
	value			AttributeValue
	}


-- naming data types --

Name ::= CHOICE { -- only one possibility for now 
	rdnSequence		RDNSequence 			
	}

RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

DistinguishedName ::= RDNSequence

RelativeDistinguishedName ::= 
	SET OF AttributeTypeAndValue  --SET SIZE (1 .. MAX) OF


-- Directory string type --

DirectoryString ::= CHOICE {
	teletexString		TeletexString,  --(SIZE (1..MAX)),
	printableString		PrintableString,  --(SIZE (1..MAX)),
	bmpString		BMPString,  --(SIZE (1..MAX)),
	universalString		UniversalString,  --(SIZE (1..MAX)),
	utf8String		UTF8String,  --(SIZE (1..MAX)),
	ia5String		IA5String,  --added for EmailAddress,
	integer			INTEGER
	}


-- certificate and CRL specific structures begin here

Certificate ::= SEQUENCE  {
	tbsCertificate		TBSCertificate,
	signatureAlgorithm	AlgorithmIdentifier,
	signature		BIT STRING
	}

TBSCertificate  ::=  SEQUENCE  {
	version		    [0] EXPLICIT Version OPTIONAL,  --DEFAULT v1
	serialNumber		CertificateSerialNumber,
	signature		AlgorithmIdentifier,
	issuer			Name,
	validity		Validity,
	subject			Name,
	subjectPublicKeyInfo	SubjectPublicKeyInfo,
	issuerUniqueID	    [1] IMPLICIT UniqueIdentifier OPTIONAL,
		-- If present, version shall be v2 or v3
	subjectUniqueID	    [2] IMPLICIT UniqueIdentifier OPTIONAL,
		-- If present, version shall be v2 or v3
	extensions	    [3] EXPLICIT Extensions OPTIONAL
		-- If present, version shall be v3
	}

Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

CertificateSerialNumber ::= INTEGER

Validity ::= SEQUENCE {
	notBefore		Time,
	notAfter		Time
	}

Time ::= CHOICE {
	utcTime			UTCTime,
	generalTime		GeneralizedTime
	}

UniqueIdentifier ::= BIT STRING

SubjectPublicKeyInfo ::= SEQUENCE {
	algorithm		AlgorithmIdentifier,
	subjectPublicKey	BIT STRING
	}


RSAPubKeyInfo ::=   SEQUENCE {
	modulus INTEGER,
	exponent INTEGER
	}

Extensions ::= SEQUENCE OF Extension  --SIZE (1..MAX) OF Extension

Extension ::= SEQUENCE {
	extnID			OBJECT IDENTIFIER,
	critical		BOOLEAN OPTIONAL,  --DEFAULT FALSE,
	extnValue		OCTET STRING
	}

AlgorithmIdentifier ::= SEQUENCE {
	algorithm		OBJECT IDENTIFIER,
	parameters		ANY OPTIONAL
	}


--extensions

AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] KeyIdentifier            OPTIONAL,
      authorityCertIssuer       [1] GeneralNames             OPTIONAL,
      authorityCertSerialNumber [2] CertificateSerialNumber  OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

KeyIdentifier ::= OCTET STRING

SubjectKeyIdentifier ::= KeyIdentifier

-- key usage extension OID and syntax

-- id-ce-keyUsage OBJECT IDENTIFIER ::=  { id-ce 15 }

KeyUsage ::= BIT STRING --{
--      digitalSignature        (0),
--      nonRepudiation          (1),
--      keyEncipherment         (2),
--      dataEncipherment        (3),
--      keyAgreement            (4),
--      keyCertSign             (5),
--      cRLSign                 (6),
--      encipherOnly            (7),
--      decipherOnly            (8) }


-- private key usage period extension OID and syntax

-- id-ce-privateKeyUsagePeriod OBJECT IDENTIFIER ::=  { id-ce 16 }

PrivateKeyUsagePeriod ::= SEQUENCE {
     notBefore       [0]     GeneralizedTime OPTIONAL,
     notAfter        [1]     GeneralizedTime OPTIONAL }
     -- either notBefore or notAfter shall be present
     
-- certificate policies extension OID and syntax
-- id-ce-certificatePolicies OBJECT IDENTIFIER ::=  { id-ce 32 }

CertificatePolicies ::= SEQUENCE OF PolicyInformation

PolicyInformation ::= SEQUENCE {
     policyIdentifier   CertPolicyId,
     policyQualifiers   SEQUENCE OF
             PolicyQualifierInfo OPTIONAL }

CertPolicyId ::= OBJECT IDENTIFIER

PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId  PolicyQualifierId,
       qualifier        ANY } --DEFINED BY policyQualifierId }

-- Implementations that recognize additional policy qualifiers shall
-- augment the following definition for PolicyQualifierId

PolicyQualifierId ::=
     OBJECT IDENTIFIER --( id-qt-cps | id-qt-unotice )

-- CPS pointer qualifier

CPSuri ::= IA5String

-- user notice qualifier

UserNotice ::= SEQUENCE {
     noticeRef        NoticeReference OPTIONAL,
     explicitText     DisplayText OPTIONAL}

NoticeReference ::= SEQUENCE {
     organization     DisplayText,
     noticeNumbers    SEQUENCE OF INTEGER }

DisplayText ::= CHOICE {
     visibleString    VisibleString  ,
     bmpString        BMPString      ,
     utf8String       UTF8String      }


-- policy mapping extension OID and syntax
-- id-ce-policyMappings OBJECT IDENTIFIER ::=  { id-ce 33 }

PolicyMappings ::= SEQUENCE OF SEQUENCE {
     issuerDomainPolicy      CertPolicyId,
     subjectDomainPolicy     CertPolicyId }


-- subject alternative name extension OID and syntax
-- id-ce-subjectAltName OBJECT IDENTIFIER ::=  { id-ce 17 }

SubjectAltName ::= GeneralNames

GeneralNames ::= SEQUENCE OF GeneralName

GeneralName ::= CHOICE {
     otherName                       [0]     AnotherName,
     rfc822Name                      [1]     IA5String,
     dNSName                         [2]     IA5String,
     x400Address                     [3]     ANY, --ORAddress,
     directoryName                   [4]     Name,
     ediPartyName                    [5]     EDIPartyName,
     uniformResourceIdentifier       [6]     IA5String,
     iPAddress                       [7]     OCTET STRING,
     registeredID                    [8]     OBJECT IDENTIFIER }

EntrustVersionInfo ::= SEQUENCE {
              entrustVers  GeneralString,
              entrustInfoFlags EntrustInfoFlags }

EntrustInfoFlags::= BIT STRING --{
--      keyUpdateAllowed
--      newExtensions     (1),  -- not used
--      pKIXCertificate   (2) } -- certificate created by pkix

-- AnotherName replaces OTHER-NAME ::= TYPE-IDENTIFIER, as
-- TYPE-IDENTIFIER is not supported in the 88 ASN.1 syntax

AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }

EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString }


-- issuer alternative name extension OID and syntax
-- id-ce-issuerAltName OBJECT IDENTIFIER ::=  { id-ce 18 }

IssuerAltName ::= GeneralNames


-- id-ce-subjectDirectoryAttributes OBJECT IDENTIFIER ::=  { id-ce 9 }

SubjectDirectoryAttributes ::= SEQUENCE OF Attribute


-- basic constraints extension OID and syntax
-- id-ce-basicConstraints OBJECT IDENTIFIER ::=  { id-ce 19 }

BasicConstraints ::= SEQUENCE {
     cA                      BOOLEAN OPTIONAL, --DEFAULT FALSE,
     pathLenConstraint       INTEGER OPTIONAL }


-- name constraints extension OID and syntax
-- id-ce-nameConstraints OBJECT IDENTIFIER ::=  { id-ce 30 }

NameConstraints ::= SEQUENCE {
     permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
     excludedSubtrees        [1]     GeneralSubtrees OPTIONAL }

GeneralSubtrees ::= SEQUENCE OF GeneralSubtree

GeneralSubtree ::= SEQUENCE {
     base                    GeneralName,
     minimum         [0]     BaseDistance OPTIONAL, --DEFAULT 0,
     maximum         [1]     BaseDistance OPTIONAL }

BaseDistance ::= INTEGER 


-- policy constraints extension OID and syntax
-- id-ce-policyConstraints OBJECT IDENTIFIER ::=  { id-ce 36 }

PolicyConstraints ::= SEQUENCE {
     requireExplicitPolicy           [0] SkipCerts OPTIONAL,
     inhibitPolicyMapping            [1] SkipCerts OPTIONAL }

SkipCerts ::= INTEGER 


-- CRL distribution points extension OID and syntax
-- id-ce-cRLDistributionPoints     OBJECT IDENTIFIER  ::=  {id-ce 31}

cRLDistributionPoints  ::= SEQUENCE OF DistributionPoint

DistributionPoint ::= SEQUENCE {
     distributionPoint       [0]     DistributionPointName OPTIONAL,
     reasons                 [1]     ReasonFlags OPTIONAL,
     cRLIssuer               [2]     GeneralNames OPTIONAL }

DistributionPointName ::= CHOICE {
     fullName                [0]     GeneralNames,
     nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }

ReasonFlags ::= BIT STRING --{
--     unused                  (0),
--     keyCompromise           (1),
--     cACompromise            (2),
--     affiliationChanged      (3),
--     superseded              (4),
--     cessationOfOperation    (5),
--     certificateHold         (6),
--     privilegeWithdrawn      (7),
--     aACompromise            (8) }


-- extended key usage extension OID and syntax
-- id-ce-extKeyUsage OBJECT IDENTIFIER ::= {id-ce 37}

ExtKeyUsageSyntax ::= SEQUENCE OF KeyPurposeId

KeyPurposeId ::= OBJECT IDENTIFIER

-- extended key purpose OIDs
-- id-kp-serverAuth      OBJECT IDENTIFIER ::= { id-kp 1 }
-- id-kp-clientAuth      OBJECT IDENTIFIER ::= { id-kp 2 }
-- id-kp-codeSigning     OBJECT IDENTIFIER ::= { id-kp 3 }
-- id-kp-emailProtection OBJECT IDENTIFIER ::= { id-kp 4 }
-- id-kp-ipsecEndSystem  OBJECT IDENTIFIER ::= { id-kp 5 }
-- id-kp-ipsecTunnel     OBJECT IDENTIFIER ::= { id-kp 6 }
-- id-kp-ipsecUser       OBJECT IDENTIFIER ::= { id-kp 7 }
-- id-kp-timeStamping    OBJECT IDENTIFIER ::= { id-kp 8 }

-- authority info access

-- id-pe-authorityInfoAccess OBJECT IDENTIFIER ::= { id-pe 1 }

AuthorityInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription

AccessDescription  ::=  SEQUENCE {
        accessMethod          OBJECT IDENTIFIER,
        accessLocation        GeneralName  }

-- subject info access

-- id-pe-subjectInfoAccess OBJECT IDENTIFIER ::= { id-pe 11 }

SubjectInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription

-- pgp creation time

PGPExtension ::= SEQUENCE {
       version             Version, -- DEFAULT v1(0)
       keyCreation         Time
}
ASN1

btest $t++, my $parser = $asn->find('Certificate');
btest $t++, my $crlp   = $asn->find('cRLDistributionPoints');

my %certs = (
  't/aj.cer'           => ["http://rootca.allianz.com/ad-ca/ad-ca.crl"],
  't/aj2.cer'          => ["http://rootca.allianz.com/sc-ad-ca/sc-ad-ca.crl"],
  't/allianz_root.cer' => ["http://rootca.allianz.com/rootca.crl"],
  't/pgpextension.der' => ["http://ca.mayfirst.org/mfpl.crl"],
  't/subca_2.cer'      => [
    "ldap://ldap.treas.gov/cn=CRL1,ou=US%20Treasury%20Root%20CA,ou=Certification%20Authorities,ou=Department%20of%20the%20Treasury,o=U.S.%20Government,c=US?authorityRevocationList"
  ],
  't/dsacert.der'           => undef,
  't/new_root_ca.cer'       => undef,
  't/telesec_799972029.crt' => undef,
  't/verisign.der'          => undef,
);

for my $file (sort keys %certs) {
  print "# $file\n";
  my $cert = loadcert($file);
  btest $t++, my $data = $parser->decode($cert);
  $data ||= {};
  my $extns = $data->{tbsCertificate}{extensions} || [];

  my ($ext) = grep { $_->{'extnID'} eq '2.5.29.31' } @$extns;
  if ($ext) {
    my $points = $crlp->decode($ext->{'extnValue'});    # decode the value
    $points = $points && $points->[0]->{'distributionPoint'}->{'fullName'};
    btest $t++, !$crlp->error or warn($crlp->error);
    my @points = grep $_, map { $_->{'uniformResourceIdentifier'} } @{$points || []};
    rtest $t++, $certs{$file}, \@points;
  }
  else {
    btest $t++, !$certs{$file};
  }
}

sub loadcert {
  my $file = shift;
  open FILE, $file || die "cannot load test certificate" . $file . "\n";
  binmode FILE;    # HELLO Windows, dont fuss with this
  my $holdTerminator = $/;
  undef $/;        # using slurp mode to read the DER-encoded binary certificate
  my $cert = <FILE>;
  $/ = $holdTerminator;
  close FILE;
  return $cert;
}

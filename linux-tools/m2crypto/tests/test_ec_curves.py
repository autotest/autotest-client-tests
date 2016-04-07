#!/usr/bin/python
# XXX memory leaks
"""
    Unit tests for M2Crypto.EC, the curves
    
    There are several ways one could unittest elliptical curves
    but we are going to only validate that we are using the 
    OpenSSL curve and that it works with ECDSA.  We will assume
    OpenSSL has validated the curves themselves.  
    
    Also, some curves are shorter than a SHA-1 digest of 160 
    bits.  To keep the testing simple, we will take advantage
    of ECDSA's ability to sign any digest length and create a 
    digset string of only 48 bits.  Remember we are testing our
    ability to access the curve, not ECDSA itself.
    
    Copyright (c) 2006 Larry Bugbee. All rights reserved.
    
"""

import unittest
#import sha
from M2Crypto import EC, Rand
from test_ecdsa import ECDSATestCase as ECDSATest


curves = [
    ('X9_62_prime256v1', 256),
    ('secp384r1', 384),
]

# The following two curves, according to OpenSSL, have a 
# "Questionable extension field!" and are not supported by 
# the OpenSSL inverse function.  ECError: no inverse.
# As such they cannot be used for signing.  They might, 
# however, be usable for encryption but that has not 
# been tested.  Until thir usefulness can be established,
# they are not supported at this time.
#curves2 = [
#    ('ipsec3', 155),
#    ('ipsec4', 185),
#]

class ECCurveTests(unittest.TestCase):
    #data = sha.sha('Kilroy was here!').digest()     # 160 bits
    data = "digest"     # keep short (48 bits) so lesser curves 
                        # will work...  ECDSA requires curve be 
                        # equal or longer than digest

    def genkey(self, curveName, curveLen):
        curve = getattr(EC, 'NID_'+curveName)
        ec = EC.gen_params(curve)
        assert len(ec) == curveLen
        ec.gen_key()
        assert  ec.check_key(), 'check_key() failure for "%s"' % curveName
        return ec

#    def check_ec_curves_genkey(self):        
#        for curveName, curveLen in curves2:
#            self.genkey(curveName, curveLen)
#
#        self.assertRaises(AttributeError, self.genkey, 
#                                          'nosuchcurve', 1)

    def sign_verify_ecdsa(self, curveName, curveLen):
        ec = self.genkey(curveName, curveLen)
        r, s = ec.sign_dsa(self.data)
        assert ec.verify_dsa(self.data, r, s)
        assert not ec.verify_dsa(self.data, s, r)            

    def test_ec_curves_ECDSA(self):
        for curveName, curveLen in curves:
            self.sign_verify_ecdsa(curveName, curveLen)

        self.assertRaises(AttributeError, self.sign_verify_ecdsa, 
                                          'nosuchcurve', 1)

#        for curveName, curveLen in curves2:
#            self.assertRaises(EC.ECError, self.sign_verify_ecdsa, 
#                              curveName, curveLen)

def suite():
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(ECCurveTests))
    return suite


if __name__ == '__main__':
    Rand.load_file('randpool.dat', -1) 
    unittest.TextTestRunner().run(suite())
    Rand.save_file('randpool.dat')


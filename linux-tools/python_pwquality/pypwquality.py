############################################################################################
## Copyright 2003, 2015 IBM Corp                                                          ##
##                                                                                        ##
## Redistribution and use in source and binary forms, with or without modification,       ##
## are permitted provided that the following conditions are met:                          ##
##        1.Redistributions of source code must retain the above copyright notice,        ##
##        this list of conditions and the following disclaimer.                           ##
##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
##        list of conditions and the following disclaimer in the documentation and/or     ##
##        other materials provided with the distribution.                                 ##
##                                                                                        ##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
############################################################################################

import pwquality

settings = pwquality.PWQSettings()
noOfFails = 8
try:
	try: settings.check("asdf")
	# Check the score before reading the config file (defaults to /etc/security/pwquality.conf)
	except pwquality.PWQError as e:
		if "The password is shorter than 8 characters" in e: noOfFails -= 1
	else: 	print "FAIL: check()"
	# Read the config file
	try: settings.read_config()
	except pwquality.PWQError as e:
		print "FAIL: read_config()"
	else:	noOfFails -= 1
	# check() should refer to the config file with maxlen=11, hence 10 characters
	try: settings.check("asdf")
	except pwquality.PWQError as e:
		if "The password is shorter than 10 characters" in e: noOfFails -= 1
	else:	print "FAIL: check()"
	# Use the set_option() method to set limit maxrepeat to 2
	try: settings.set_option("maxrepeat=2")
	except pwquality.PWQError as e:
		print "FAIL: set_option()"
	else:	noOfFails -= 1
	# Check the score after using set_option
	try: settings.check("aaaaaaqwerty")
	except pwquality.PWQError as e:
		if "The password contains more than 2 same characters consecutively" in e: noOfFails -= 1
	else: print "FAIL: check()"
	# Check the score for a password that satisfies all limits
	try: settings.check("vndkjsldorutjkd")
	except pwquality.PWQError as e:
		print "FAIL: check()"
	else: 	noOfFails -= 1
	# Test the generate method and check the score of the generated password
	try: pword = settings.generate(30)
	except pwquality.PWQError as e:
	        print "FAIL: generate()"
	else:   noOfFails -= 1
	try: settings.check(pword)
	except pwquality.PWQError as e:
	        print "FAIL: check()"
	else:
		noOfFails -= 1
except:	"Unexpected error"
exit(noOfFails)

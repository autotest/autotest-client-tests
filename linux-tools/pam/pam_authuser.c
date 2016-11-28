/*
 * ############################################################################################
 * ## Copyright 2003, 2015 IBM Corp                                                          ##
 * ##                                                                                        ##
 * ## Redistribution and use in source and binary forms, with or without modification,       ##
 * ## are permitted provided that the following conditions are met:                          ##
 * ##        1.Redistributions of source code must retain the above copyright notice,        ##
 * ##        this list of conditions and the following disclaimer.                           ##
 * ##  2.Redistributions in binary form must reproduce the above copyright notice, this      ##
 * ##        list of conditions and the following disclaimer in the documentation and/or     ##
 * ##        other materials provided with the distribution.                                 ##
 * ##                                                                                        ##
 * ## THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS AND ANY EXPRESS       ##
 * ## OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        ##
 * ## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ##
 * ## THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    ##
 * ## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF     ##
 * ## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ##
 * ## HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,  ##
 * ## OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS  ##
 * ## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                           ##
 * ############################################################################################
 * File:	pam_authuser.c
 *
 * Description: A program that will call pam_authenticate and pam_acct_mgmt
 *		functions to authenticate and check access permissions to 
 *		a given user.
 *
 * Author:	Manoj Iyer manjo@mail.utexas.edu
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>
#include <security/pam_appl.h>
#include <security/pam_misc.h>

/* pam conversation structure */
static struct 
pam_conv conv_str = {
	misc_conv, 
	NULL
};

/*
 * Function:	main
 *
 * Description: Entry point to this program, initializes pam, calls pam
 *		library functions to authorise and authenticate the user
 *		that is provided as input to this program.
 *
 * Input:	user name
 *
 * Output:	The program prints the following to stdout:
 *		USAGE_ERR	 - user provided no input or more than one user 
 *		NAME_ERR	 - name of this program in not pam_authuser
 *		PAM_START_ERR	 - error initializing pam
 *		PAM_AUTH_ERR	 - error returned by pam_authenticate()
 *		PAM_ACCNT_ERR	 - error returned by pam_acct_mgmt()
 *		PAM_END_ERR	 - error closing pam
 *		PAM_AUTH_SUCCESS - pam authentication success
 *
 * Exit:	EXIT_SUCCESS  - on success
 *		EXIT_FAILURE  - on failure
 */
int
main(int   argc, char *argv[])
{
	int	retval;			/* return value from system calls	*/
	char	*progname;		/* name of this program			*/
	char	*user;			/* user name that to be authenticated	*/
	pam_handle_t *pamh = NULL;	/* pam handle pointer			*/

	/* if this command is not invoked with user name as a parameter
	 * report usage error
	 */
	if (argc != 2) {
 		fprintf(stdout, "USAGE_ERR\n");
		exit(EXIT_FAILURE);
	}

	/* if this program is not named pam_authuser, name that is 
	 * registerd in /etc/pam.conf report error
	 */
	progname = basename(argv[0]);
	if (strncmp(progname, "pam_authuser", strlen(progname))) {
		fprintf(stdout, "NAME_ERR\n");
		exit(EXIT_FAILURE);
	}
	user = argv[1];

	/* initialize pam */
	if ((retval = pam_start(progname, user, &conv_str, &pamh)) 
				!= PAM_SUCCESS) {
		fprintf(stdout, "PAM_START_ERR %s\n",pam_strerror(pamh,retval));
		exit(EXIT_FAILURE);
	}

	/* authenticate user */
	if ((retval = pam_authenticate(pamh, 0)) != PAM_SUCCESS) {
		fprintf(stdout, "PAM_AUTH_ERR %s\n",pam_strerror(pamh,retval));
		exit(EXIT_FAILURE);
	}

	/* check user access permissions */
	if ((retval = pam_acct_mgmt(pamh, 0)) != PAM_SUCCESS) {
		fprintf(stdout, "PAM_ACCNT_ERR %s\n",pam_strerror(pamh,retval));
		exit(EXIT_FAILURE);
	}

	/* if authtication and access perms are ok print success */
	fprintf(stdout, "PAM_AUTH_SUCCESS\n");

	/* end pam */
	if ((retval = pam_end(pamh, retval)) != PAM_SUCCESS) {
		fprintf(stdout, "PAM_END_ERR\n");
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}

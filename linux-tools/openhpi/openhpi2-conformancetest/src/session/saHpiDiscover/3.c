/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiDiscover
 * Description:   
 *   Do discovery when the domain's sessionId exists.
 *   Expected return: SA_OK.
 * Line:        P35-10:P35-10
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Do discovery when the domain's sessionId exists.
*
*   Expected return:  saHpiDiscover() returns SA_OK.
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	SaHpiSessionIdT session;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	// Open a session
	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session, NULL);

	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	}

	if (retval == SAF_TEST_UNKNOWN) {
		// Perform Discovery
		status = saHpiDiscover(session);

		if (status != SA_OK) {
			e_print(saHpiDiscover, SA_OK, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
	}

	if (retval != SAF_TEST_UNRESOLVED) {
		status = saHpiSessionClose(session);
	}

	return (retval);
}

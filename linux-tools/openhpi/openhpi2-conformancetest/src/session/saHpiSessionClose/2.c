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
 *      David Benedetto <dab7@cisunix.unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSessionClose
 * Description:   
 *   Close the same session twice in a row.
 *   Expected return: SA_ERR_HPI_INVALID_SESSION.
 * Line:        P34-2:P34-2
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Close the same session twice in a row.
*
*   Expected return:  saHpiSessionClose() returns SA_ERR_HPI_INVALID_SESSION
*                     on the second close.
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

	//
	// Open a session
	//
	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session, NULL);

	if (status != SA_OK) {
		//Unable to set up the test
		e_print(saHpiSessionOpen, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	}

	if (retval == SAF_TEST_UNKNOWN) {
		//
		// Close the session
		//
		status = saHpiSessionClose(session);
		if (status != SA_OK) {
			//Unable to set up the test
			e_print(saHpiSessionClose, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		//
		// Close the same session a second time
		//
		status = saHpiSessionClose(session);
		if (status == SA_ERR_HPI_INVALID_SESSION)
			retval = SAF_TEST_PASS;
		else {
			e_print(saHpiSessionClose, SA_ERR_HPI_INVALID_SESSION,
				status);
			retval = SAF_TEST_FAIL;
		}
	}

	return (retval);
}

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
 * Function:    saHpiDomainTagSet
 * Description:   
 *   Pass in an invalid SessionId.
 *   Expected return: SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Pass in an invalid SessionId.
*
*   Expected return:  saHpiDomainTagSet() returns 
*                      SA_ERR_HPI_INVALID_SESSION.
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successful
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	SaHpiSessionIdT session;
	SaHpiDomainInfoT DomainInfo;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Open a session
	//
	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session, NULL);

	if (status == SA_OK) {
		//
		// Retrieve the current DomainTag
		// 
		status = saHpiDomainInfoGet(session, &DomainInfo);
		if (status != SA_OK) {
			e_print(saHpiDomainInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}

		if (retval == SAF_TEST_UNKNOWN) {
			// Set the same Tag with an INVALID_SESSION_ID
			status =
			    saHpiDomainTagSet(INVALID_SESSION_ID,
					      &DomainInfo.DomainTag);

			if (status != SA_ERR_HPI_INVALID_SESSION) {
				e_print(saHpiDomainTagSet,
					SA_ERR_HPI_INVALID_SESSION, status);
				retval = SAF_TEST_FAIL;
			} else
				retval = SAF_TEST_PASS;
		}
		//
		// Close the session
		//
		status = saHpiSessionClose(session);

		if (status != SA_OK) {
			m_print("Session was not closed!");
			e_print(saHpiSessionClose, SA_OK, status);
		}
	} else {
		//otherwise, If Session Open Failed
		//Unable to set up the test
		e_print(saHpiSessionOpen, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	}

	return (retval);
}

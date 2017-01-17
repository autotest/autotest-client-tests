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
 * Function:    saHpiSessionOpen
 * Description:   
 *   Open a new session passing a buffer for security parameters.
 *   Expected return:  SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P33-20:P33-20
 */
#include <stdio.h>
#include <stdlib.h>
#include "saf_test.h"
/**********************************************************
*
*   Open a new session passing a buffer for security parameters.
*
*   Expected return:  saHpiSessionOpen() returns 
*                     SA_ERR_HPI_INVALID_PARAMS.
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
	void *allocation;

	// Create an allocation to hold an undeterminable amount of data
	// In case the function succeeds

	allocation = malloc(1024);
	if (allocation == NULL) {
		retval = SAF_TEST_UNRESOLVED;
		m_print("Failed to allocate memory!");
	} else {
		//
		// Pass in a buffer pointer for the security parameters
		//
		status =
		    saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session,
				     allocation);

		if (status == SA_ERR_HPI_INVALID_PARAMS) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiSessionOpen,
				SA_ERR_HPI_INVALID_PARAMS, status);
		}

		// If by chance the call did work, then clean up
		if (status == SA_OK) {
			status = saHpiSessionClose(session);
		}

		free(allocation);
	}

	return (retval);
}

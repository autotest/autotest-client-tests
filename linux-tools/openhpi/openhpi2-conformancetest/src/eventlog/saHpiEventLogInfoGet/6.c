/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 * Copyright (c) 2005, University of New Hampshire
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogInfoGet
 * Description:   
 *   Call saHpiEventLogInfoGet while passing in a NULL pointer for Info.
 *   saHpiEventLogInfoGet() returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P48-22:P48-22
 *
 */
#include <stdio.h>
#include "saf_test.h"

int Test(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	//  Call saHpiEventLogInfoGet passing in a NULL pointer for Info.
	//

	status = saHpiEventLogInfoGet(sessionId, resourceId, NULL);
	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		e_print(saHpiEventLogInfoGet,
			SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
	}

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	return Test(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
}

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaHpiResourceIdT resource_id = rpt_entry.ResourceId;
	int retval = SAF_TEST_NOTSUPPORT;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {
		retval = Test(session_id, resource_id);
	}

	return retval;
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, NULL, Test_Domain);

	return (retval);
}

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
 * Function:    saHpiEventLogTimeGet
 * Description:   
 *   Call saHpiEventLogTimeGet passing in a NULL pointer for Time.
 *   saHpiEventLogTimeGet() returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P54-20:P54-20
 *
 */

#include <stdio.h>
#include "saf_test.h"
int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	//  Call saHpiEventLogTimeGet passing in a NULL pointer 
	//    for Time.
	status = saHpiEventLogTimeGet(session, resource, NULL);
	if (status == SA_ERR_HPI_INVALID_PARAMS)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiEventLogTimeGet, SA_ERR_HPI_INVALID_PARAMS,
			status);
		retval = SAF_TEST_FAIL;
	}

	return (retval);
}

int Resource_Test(SaHpiSessionIdT session,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {

		retval = Test_Resource(session, rpt_entry.ResourceId);
	} else {
		// This resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;
	}

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	// On each domain, test the domain event log.
	retval = Test_Resource(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

	return (retval);
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

	retval = process_all_domains(Resource_Test, NULL, Test_Domain);

	return (retval);
}

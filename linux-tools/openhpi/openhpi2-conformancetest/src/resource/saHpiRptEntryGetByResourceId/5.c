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
 * Function:    saHpiRptEntryGetByResourceId
 * Description:   
 *   Call saHpiRptEntryGetByResourceId comparing the Reports 
 *   received from the call to the one which we received from
 *   the saHpiRptEntryGet call.
 *   Expected return:  call returns with successful status
 * Line:        P42-18:P42-19
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT entryId;
	SaHpiEntryIdT nextEntryId;
	SaHpiRptEntryT Report, ResReport;

	retval = SAF_TEST_PASS;
	nextEntryId = SAHPI_FIRST_ENTRY;
	while (nextEntryId != SAHPI_LAST_ENTRY) {
		entryId = nextEntryId;
		//
		// Obtain a ResourceId
		//
		status = saHpiRptEntryGet(session,
					  entryId, &nextEntryId, &Report);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_NOTSUPPORT;
			break;
		} else if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
			break;
		} else {
			status = saHpiRptEntryGetByResourceId(session,
							      Report.ResourceId,
							      &ResReport);
			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiRptEntryGetByResourceId, SA_OK,
					status);
				break;
			} else if (Report.EntryId != ResReport.EntryId) {
				// Compare the Reports received from the saHpiRptEntryGet call
				// the the one received with the saHpiRptEntryGetByResourceId call.
				//
				// Compare the EntryId's of both to make sure that they are the 
				// same. 
				m_print
				    ("Function \"saHpiRptEntryGetByResourceId\" works abnormally!");
				m_print
				    ("Function did not return the same report given the same ResourceId!");
				retval = SAF_TEST_FAIL;
				break;
			}
		}
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

	retval = process_single_domain(Test_Resource);

	return (retval);
}

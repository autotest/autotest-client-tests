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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourceSeveritySet
 * Description:   
 *   Call saHpiResourceSeveritySet() passing in an invalid value for Severity.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P43-19:P43-20
 */

#include <stdio.h>
#include "saf_test.h"

int setSeverity(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
		SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;

	status = saHpiResourceSeveritySet(sessionId, resourceId, severity);
	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else if (status != SA_OK) {
		retval = SAF_TEST_FAIL;
		e_print(saHpiResourceSeveritySet, SA_ERR_HPI_INVALID_PARAMS,
			status);
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	int i;
	SaErrorT status;
	SaHpiResourceIdT resource_id;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT severity[] = { SAHPI_OK + 1, SAHPI_DEBUG - 1,
		SAHPI_DEBUG + 1, SAHPI_ALL_SEVERITIES - 1,
		SAHPI_ALL_SEVERITIES
	};

	resource_id = rpt_entry.ResourceId;

	// test many invalid severities

	for (i = 0; i < 5; i++) {
		retval = setSeverity(session_id, resource_id, severity[i]);
		if (retval != SAF_TEST_PASS) {
			break;
		}
	}

	return retval;
}

int main()
{
	return process_all_domains(Test_Resource, NULL, NULL);
}

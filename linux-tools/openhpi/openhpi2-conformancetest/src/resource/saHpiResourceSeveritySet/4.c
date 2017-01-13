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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourceSeveritySet
 * Description:  
 *      Call the function with valid paramaters.
 *      Expected return: SA_OK.
 * Line:        P43-18:p43-18
 */

#include <stdio.h>
#include "saf_test.h"

int setSeverity(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId,
		SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;
	SaHpiRptEntryT rptEntry;

	status = saHpiResourceSeveritySet(sessionId, resourceId, severity);
	if (status != SA_OK) {
		///
		// Note: SA_ERR_HPI_INVALID_CMD suggest that the plug-in
		// does not support this call.  This is a non-conformance issue.
		// 
		retval = SAF_TEST_FAIL;
		e_print(saHpiResourceSeveritySet, SA_OK, status);
	} else {
		status = saHpiRptEntryGetByResourceId(sessionId,
						      resourceId, &rptEntry);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiRptEntryGetByResourceId, SA_OK, status);
		} else if (rptEntry.ResourceSeverity == severity) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			m_print("Invalid severity level of RPT!");
		}
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	int i;
	SaErrorT status;
	SaHpiResourceIdT resource_id;
	SaHpiSeverityT severity_old;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT severity[] = { SAHPI_DEBUG, SAHPI_OK,
		SAHPI_INFORMATIONAL, SAHPI_MINOR,
		SAHPI_MAJOR, SAHPI_CRITICAL
	};

	resource_id = rpt_entry.ResourceId;
	severity_old = rpt_entry.ResourceSeverity;

	// test all valid severities

	for (i = 0; i < 6; i++) {
		retval = setSeverity(session_id, resource_id, severity[i]);
		if (retval != SAF_TEST_PASS) {
			break;
		}
	}

	// Restore original severity
	status =
	    saHpiResourceSeveritySet(session_id, resource_id, severity_old);
	if (status != SA_OK) {
		e_print(saHpiResourceSeveritySet, SA_OK, status);
	}

	return retval;
}

int main()
{
	return process_all_domains(Test_Resource, NULL, NULL);
}

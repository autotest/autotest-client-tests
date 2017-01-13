/*      -*- linux-c -*-
 *
 * Copyright (c) 2003 by Intel Corp.
 * (C) Copyright IBM Corp. 2004, 2005
 *
 *   This program is free software; you can redistribute it and/or modify 
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or 
 *   (at your option) any later version.
 *   This program is distributed in the hope that it will be useful, 
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *   GNU General Public License for more details. 
 *   You should have received a copy of the GNU General Public License 
 *   along with this program; if not, write to the Free Software 
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 
 *   USA 
 *
 * Author(s):
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAutoInsertTimeoutGet
 * Description:
 *   Request an Extraction action when in the EXTRACTION_PENDING state.
 *   saHpiHotSwapActionRequest() returns SA_ERR_HPI_INVALID_REQUEST.
 * Line:        P148-34:P148-34
 *    
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int Testcase(SaHpiSessionIdT session,
	     SaHpiResourceIdT resource, int *returnvalue, SaHpiBoolT * restore)
{

	SaErrorT status;
	if (*returnvalue == SAF_TEST_UNKNOWN) {
		status = saHpiHotSwapActionRequest(session,
						   resource,
						   SAHPI_HS_ACTION_EXTRACTION);
		if (status != SA_ERR_HPI_INVALID_REQUEST) {
			e_print(saHpiHotSwapActionRequest,
				SA_ERR_HPI_INVALID_REQUEST, status);
			*returnvalue = SAF_TEST_FAIL;
		} else {
			*restore = SAHPI_TRUE;
			*returnvalue = SAF_TEST_PASS;
		}
	}
	return (*returnvalue);
}
int Activate(SaHpiSessionIdT session,
	     SaHpiResourceIdT resource, int *returnvalue, SaHpiBoolT * restore)
{

	SaErrorT status;
	if ((*returnvalue == SAF_TEST_UNKNOWN) || (*restore != SAHPI_FALSE)) {
		status = saHpiResourceActiveSet(session, resource);
		if (*restore == SAHPI_FALSE) {
			if (status != SA_OK) {
				e_print(saHpiResourceActiveSet, SA_OK, status);
				*returnvalue = SAF_TEST_UNRESOLVED;
			}
		}
	}
	return (*returnvalue);
}
int Inactivate(SaHpiSessionIdT session,
	       SaHpiResourceIdT resource,
	       int *returnvalue, SaHpiBoolT * restore)
{

	SaErrorT status;
	if ((*returnvalue == SAF_TEST_UNKNOWN) || (*restore != SAHPI_FALSE)) {
		status = saHpiResourceInactiveSet(session, resource);
		if (*restore == SAHPI_FALSE) {
			if (status != SA_OK) {
				e_print(saHpiResourceInactiveSet,
					SA_OK, status);
				*returnvalue = SAF_TEST_UNRESOLVED;
			}
		}
	}
	return (*returnvalue);
}
int Insert(SaHpiSessionIdT session,
	   SaHpiResourceIdT resource, int *returnvalue, SaHpiBoolT * restore)
{

	SaErrorT status;
	if ((*returnvalue == SAF_TEST_UNKNOWN) || (*restore != SAHPI_FALSE)) {
		status = saHpiHotSwapActionRequest(session,
						   resource,
						   SAHPI_HS_ACTION_INSERTION);
		if (*restore == SAHPI_FALSE) {
			if (status != SA_OK) {
				e_print(saHpiHotSwapActionRequest,
					SA_OK, status);
				*returnvalue = SAF_TEST_UNRESOLVED;
			}
		}
	}
	return (*returnvalue);
}
int Extract(SaHpiSessionIdT session,
	    SaHpiResourceIdT resource, int *returnvalue, SaHpiBoolT * restore)
{

	SaErrorT status;
	if ((*returnvalue == SAF_TEST_UNKNOWN) || (*restore != SAHPI_FALSE)) {
		status = saHpiHotSwapActionRequest(session,
						   resource,
						   SAHPI_HS_ACTION_EXTRACTION);
		if (*restore == SAHPI_FALSE) {
			if (status != SA_OK) {
				e_print(saHpiHotSwapActionRequest,
					SA_OK, status);
				*returnvalue = SAF_TEST_UNRESOLVED;
			}
		}
	}
	return (*returnvalue);
}

int process_resource(SaHpiSessionIdT session_id, SaHpiRptEntryT report,
		     callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiHsStateT state_old;
	SaErrorT status;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiBoolT Restore = SAHPI_FALSE;

	if ((report.ResourceCapabilities &
	     SAHPI_CAPABILITY_MANAGED_HOTSWAP) &&
	    (report.ResourceCapabilities & SAHPI_CAPABILITY_FRU)) {
		resource_id = report.ResourceId;

		status =
		    saHpiHotSwapStateGet(session_id, resource_id, &state_old);
		if (status != SA_OK) {
			e_print(saHpiHotSwapStateGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
		}
		if (ret == SAF_TEST_UNKNOWN) {
			switch (state_old) {
			case SAHPI_HS_STATE_ACTIVE:
				Extract(session_id, resource_id, &ret,
					&Restore);
				Testcase(session_id, resource_id, &ret,
					 &Restore);
				Activate(session_id, resource_id, &ret,
					 &Restore);
				break;
			case SAHPI_HS_STATE_EXTRACTION_PENDING:
				Testcase(session_id, resource_id, &ret,
					 &Restore);
				break;
			case SAHPI_HS_STATE_INSERTION_PENDING:
				Activate(session_id, resource_id, &ret,
					 &Restore);
				Extract(session_id, resource_id, &ret,
					&Restore);
				Testcase(session_id, resource_id, &ret,
					 &Restore);
				Inactivate(session_id, resource_id, &ret,
					   &Restore);
				Insert(session_id, resource_id, &ret, &Restore);
				break;
			case SAHPI_HS_STATE_INACTIVE:
				Insert(session_id, resource_id, &ret, &Restore);
				Activate(session_id, resource_id, &ret,
					 &Restore);
				Extract(session_id, resource_id, &ret,
					&Restore);
				Testcase(session_id, resource_id, &ret,
					 &Restore);
				Inactivate(session_id, resource_id, &ret,
					   &Restore);
				break;
			default:
				m_print
				    ("Function \"saHpiHotSwapStateGet\" works abnormally!\n"
				     "\tstate recieved is not valid!");
				ret = SAF_TEST_UNRESOLVED;
			}
		}
	} else {
		// Not a Full Hot Swap model supported Resource
		ret = SAF_TEST_NOTSUPPORT;
	}
	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(process_resource, NULL, NULL);

	return ret;
}

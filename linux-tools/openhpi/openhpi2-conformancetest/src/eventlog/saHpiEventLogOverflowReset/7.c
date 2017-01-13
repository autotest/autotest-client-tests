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
 * Authors:
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogOverflowReset
 * Description:   
 *   Fill the event log to overflow. Clear the overflow flag.  Add an
 *   additional event log entry. Verify that the overflow flag has been 
 *   reset.
 *   saHpiEventLogOverflowReset() returns SA_OK, and the overflow is set
 *   again, after another event log entry has been added.
 * Line:        P58-20:P58-22
 *
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventLogInfoT info;
	SaHpiEventT EvtEntry;
	int i = 0;
	int size;
	SaHpiBoolT didSaveState = SAHPI_FALSE;
	SaHpiBoolT savedState;

	status = saHpiEventLogStateGet(session, resource, &savedState);
	if (status != SA_OK) {
		e_print(saHpiEventLogStateGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	}

	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiEventLogStateSet(session, resource, SAHPI_FALSE);
		if (status == SA_OK) {
			didSaveState = SAHPI_TRUE;
		} else {
			e_print(saHpiEventLogStateSet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		// Create the entry to fill the log with.
		EvtEntry.EventType = SAHPI_ET_USER;
		EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
		EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
		EvtEntry.Severity = SAHPI_OK;
		strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
			TEST_STRING, TEST_STRING_LENGTH);
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
		    TEST_STRING_LENGTH;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
		    SAHPI_LANG_ENGLISH;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
		    SAHPI_TL_TYPE_TEXT;

		status = saHpiEventLogInfoGet(session, resource, &info);

		if (status != SA_OK) {
			e_print(saHpiEventLogInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			// early exit if the overflow is not resetable.  
			if (info.OverflowResetable == SAHPI_FALSE) {
				retval = SAF_TEST_NOTSUPPORT;
				goto finish;
			}

			size = (info.Size - info.Entries) + 1;	//add one extra to create the overflow
			for (i = 0; i < size; i++) {
				status = saHpiEventLogEntryAdd(session,
							       resource,
							       &EvtEntry);
				if (!((status == SA_OK) ||
				      (status == SA_ERR_HPI_OUT_OF_SPACE))) {
					e_print(saHpiEventLogEntryAdd,
						SA_OK
						|| SA_ERR_HPI_OUT_OF_SPACE,
						status);
					retval = SAF_TEST_UNRESOLVED;
					break;
				}
			}
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		// Call saHpiEventLogInfoGet
		status = saHpiEventLogInfoGet(session, resource, &info);
		if (status != SA_OK) {
			e_print(saHpiEventLogInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (info.OverflowFlag == SAHPI_FALSE) {
				retval = SAF_TEST_UNRESOLVED;
			}
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {

		//
		//  Call saHpiEventLogOverflowReset  
		//
		status = saHpiEventLogOverflowReset(session, resource);
		if (status != SA_OK) {
			e_print(saHpiEventLogOverflowReset, SA_OK, status);
			retval = SAF_TEST_FAIL;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		// Call saHpiEventLogInfoGet
		status = saHpiEventLogInfoGet(session, resource, &info);
		if (status != SA_OK) {
			e_print(saHpiEventLogInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (info.OverflowFlag != SAHPI_FALSE) {
				e_print(saHpiEventLogInfoGet,
					info.OverflowFlag == SAHPI_FALSE,
					status);
				retval = SAF_TEST_UNRESOLVED;
			}
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		// Add another entry to reset the Overflow flag
		status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
		if (!((status == SA_OK) || (status == SA_ERR_HPI_OUT_OF_SPACE))) {
			e_print(saHpiEventLogEntryAdd,
				SA_OK || SA_ERR_HPI_OUT_OF_SPACE, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		// Call saHpiEventLogInfoGet
		status = saHpiEventLogInfoGet(session, resource, &info);
		if (status != SA_OK) {
			e_print(saHpiEventLogInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (info.OverflowFlag != SAHPI_FALSE) {
				// the overflow flag is set after
				retval = SAF_TEST_PASS;
			} else {
				m_print
				    ("Function \"saHpiEventLogOverflowReset\" works abnormally!\n"
				     "\tOverflow Flag not re-set with adding another event log entry.");
				retval = SAF_TEST_FAIL;
			}
		}
	}
	// clean up
	status = saHpiEventLogClear(session, resource);
      finish:
	if (didSaveState) {
		status = saHpiEventLogStateSet(session, resource, savedState);
	}
	return (retval);
}

int Resource_Test(SaHpiSessionIdT session,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG)
		retval = Test_Resource(session, rpt_entry.ResourceId);
	else			// This resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;

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

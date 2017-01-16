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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryGet
 * Description:   
 *   Clear the event log. Then add several entries to the event log. Get the 
 *   newest entry and compare it to what we added.
 *   saHpiEventLogEntryGet() returns SA_OK.
 * Line:        P50-11:P50-12
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
	SaHpiEventLogEntryIdT PrevLogEntry;
	SaHpiEventLogEntryIdT NextLogEntry;
	SaHpiEventLogEntryT LogEntry;
	SaHpiEventT EvtEntry;
	SaHpiBoolT EnableState;

	//
	// Save Event Log State.
	//
	status = saHpiEventLogStateGet(session, resource, &EnableState);
	if (status != SA_OK) {
		// Retrieving the event log failed
		e_print(saHpiEventLogStateGet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}
	//
	// Set EventLogState to false
	//
	status = saHpiEventLogStateSet(session, resource, SAHPI_FALSE);
	if (status != SA_OK) {
		// Setting event log  state failed
		e_print(saHpiEventLogStateSet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}
	//
	//  Clear the event log.
	// 
	status = saHpiEventLogClear(session, resource);
	if (status != SA_OK) {
		// Clearing the event log failed
		m_print("Clearing the Event Log Failed!");
		retval = SAF_TEST_UNRESOLVED;
	} else {
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

		status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
		if (status != SA_OK) {
			e_print(saHpiEventLogEntryAdd, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		EvtEntry.Severity = SAHPI_OK;
		status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
		if (status != SA_OK) {
			e_print(saHpiEventLogEntryAdd, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		EvtEntry.Severity = SAHPI_INFORMATIONAL;
		status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
		if (status != SA_OK) {
			e_print(saHpiEventLogEntryAdd, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiEventLogEntryGet(session,
					       resource,
					       SAHPI_NEWEST_ENTRY,
					       &PrevLogEntry,
					       &NextLogEntry,
					       &LogEntry, NULL, NULL);
		if (status != SA_OK) {
			e_print(saHpiEventLogEntryGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (LogEntry.Event.Severity == SAHPI_INFORMATIONAL)
				retval = SAF_TEST_PASS;
			else {
				m_print
				    ("\"saHPiEventLogEntryGet\": Log entry returned by call specifying SAHPI_NEWEST_ENTRY did not return the newest!");
				retval = SAF_TEST_FAIL;
			}
		}
	}
	//
	// Restore EventLog State
	//
	status = saHpiEventLogStateSet(session, resource, EnableState);
	if (status != SA_OK) {
		e_print(saHpiEventLogStateSet, SA_OK, status);
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

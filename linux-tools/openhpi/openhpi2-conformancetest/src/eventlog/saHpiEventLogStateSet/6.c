/*
 * (C) Copyright IBM Corp. 2004, 2005
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogStateSet
 * Description:   
 *   Disable the event log state.  Get event log state. Add an event by
 *   saHpiEventLogEntryAdd(). Get the event log entry and verify it does exist.
 *   saHpiEventLogStateSet() returns SA_OK, and the added event is found
 *   in the event log.
 * Line:        P57-21:P57-22
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

SaHpiBoolT is_user_event(SaHpiEventLogEntryT * entry)
{
	return (entry->Event.EventType == SAHPI_ET_USER) &&
	    (entry->Event.Severity == SAHPI_OK) &&
	    (entry->Event.EventDataUnion.UserEvent.UserEventData.DataLength ==
	     TEST_STRING_LENGTH)
	    && (entry->Event.EventDataUnion.UserEvent.UserEventData.Language ==
		SAHPI_LANG_ENGLISH)
	    && (entry->Event.EventDataUnion.UserEvent.UserEventData.DataType ==
		SAHPI_TL_TYPE_TEXT)
	    && (entry->Event.EventDataUnion.UserEvent.UserEventData.DataType ==
		SAHPI_TL_TYPE_TEXT)
	    &&
	    (strncmp
	     (entry->Event.EventDataUnion.UserEvent.UserEventData.Data,
	      TEST_STRING, TEST_STRING_LENGTH) == 0);
}

SaErrorT contains_user_event(SaHpiSessionIdT session,
			     SaHpiResourceIdT resource, SaHpiBoolT * found)
{
	SaErrorT status = SA_OK;
	SaHpiEventLogEntryIdT entryId;
	SaHpiEventLogEntryIdT PrevLogEntry;
	SaHpiEventLogEntryIdT NextLogEntry;
	SaHpiEventLogEntryT LogEntry;

	*found = SAHPI_FALSE;
	entryId = SAHPI_NEWEST_ENTRY;
	while (entryId != SAHPI_NO_MORE_ENTRIES && !(*found)) {
		status = saHpiEventLogEntryGet(session,
					       resource,
					       entryId,
					       &PrevLogEntry,
					       &NextLogEntry,
					       &LogEntry, NULL, NULL);
		if (status == SA_OK) {
			entryId = PrevLogEntry;
			*found = is_user_event(&LogEntry);
		} else if (status == SA_ERR_HPI_INVALID_PARAMS) {
			status = SA_OK;	// everything is okay, but did not find event
			break;
		} else {
			e_print(saHpiEventLogEntryGet,
				SA_OK || SA_ERR_HPI_INVALID_PARAMS, status);
			break;
		}
	}

	return status;
}

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;
	SaHpiBoolT SavedState, DisableState;
	SaHpiBoolT found;

	DisableState = SAHPI_FALSE;

	status = saHpiEventLogStateGet(session, resource, &SavedState);
	if (status != SA_OK) {
		e_print(saHpiEventLogStateGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		//
		//  Disable the event log.
		//
		status = saHpiEventLogStateSet(session, resource, DisableState);
		if (status == SA_ERR_HPI_CAPABILITY) {
			e_print(saHpiEventLogStateSet,
				status != SA_ERR_HPI_CAPABILITY, status);
			retval = SAF_TEST_FAIL;
		}
		if (retval == SAF_TEST_UNKNOWN) {
			status = saHpiEventLogClear(session, resource);
			if (status != SA_OK) {
				e_print(saHpiEventLogClear, SA_OK, status);
				retval = SAF_TEST_UNRESOLVED;
			}
		}
		if (retval == SAF_TEST_UNKNOWN) {
			EvtEntry.EventType = SAHPI_ET_USER;
			EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
			EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
			EvtEntry.Severity = SAHPI_OK;
			strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.
				Data, TEST_STRING, TEST_STRING_LENGTH);
			EvtEntry.EventDataUnion.UserEvent.UserEventData.
			    DataLength = TEST_STRING_LENGTH;
			EvtEntry.EventDataUnion.UserEvent.UserEventData.
			    Language = SAHPI_LANG_ENGLISH;
			EvtEntry.EventDataUnion.UserEvent.UserEventData.
			    DataType = SAHPI_TL_TYPE_TEXT;

			status = saHpiEventLogEntryAdd(session,
						       resource, &EvtEntry);
			if (status != SA_OK) {
				e_print(saHpiEventLogEntryAdd, SA_OK, status);
				retval = SAF_TEST_UNRESOLVED;
			}
		}
		if (retval == SAF_TEST_UNKNOWN) {
			status = contains_user_event(session, resource, &found);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
			} else if (found) {
				retval = SAF_TEST_PASS;
			} else {
				m_print
				    ("Failed to find user event in the Event Log!");
				retval = SAF_TEST_FAIL;
			}
		}

		status = saHpiEventLogClear(session, resource);

		// restore
		status = saHpiEventLogStateSet(session, resource, SavedState);
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

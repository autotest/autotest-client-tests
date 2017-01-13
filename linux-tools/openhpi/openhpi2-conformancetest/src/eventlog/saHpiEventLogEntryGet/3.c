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
 *   Add an event log entry then get the entry.
 *   saHpiEventLogEntryGet() returns SA_OK.
 * Line:        P50-11:P50-12
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

/*************************************************************
 *
 * sameUserEventData()
 *
 * Compare the User Event Data for equality.
 *
 * **********************************************************/

SaHpiBoolT sameUserEventData(SaHpiEventT * event1, SaHpiEventT * event2)
{
	int i;
	SaHpiBoolT isSame = SAHPI_TRUE;

	SaHpiTextBufferT *buf1 =
	    &(event1->EventDataUnion.UserEvent.UserEventData);
	SaHpiTextBufferT *buf2 =
	    &(event2->EventDataUnion.UserEvent.UserEventData);

	if (buf1->DataType != buf2->DataType) {
		isSame = SAHPI_FALSE;
	} else if (buf1->Language != buf2->Language) {
		isSame = SAHPI_FALSE;
	} else if (buf1->DataLength != buf2->DataLength) {
		isSame = SAHPI_FALSE;
	} else {
		for (i = 0; i < buf1->DataLength && !isSame; i++) {
			if (buf1->Data[i] != buf2->Data[i]) {
				isSame = SAHPI_FALSE;
			}
		}
	}

	return isSame;
}

/*************************************************************
 *
 * sameUserEvent()
 *
 * Compares two User Events.  It is assumed that one event
 * is created by the application and the other is retrieved
 * from the event log. 
 *
 * **********************************************************/

SaHpiBoolT sameUserEvent(SaHpiEventT * event1, SaHpiEventT * event2)
{
	SaHpiBoolT isSame = SAHPI_TRUE;

	if (event1->Source != event2->Source) {
		isSame = SAHPI_FALSE;
	} else if (event1->EventType != event2->EventType) {
		isSame = SAHPI_FALSE;
	} else if (event1->Severity != event2->Severity) {
		isSame = SAHPI_FALSE;
	} else if (event1->Timestamp != event2->Timestamp) {
		isSame = SAHPI_FALSE;
	} else {
		isSame = sameUserEventData(event1, event2);
	}

	return isSame;
}

int test_res(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventLogEntryIdT PrevLogEntry;
	SaHpiEventLogEntryIdT NextLogEntry;
	SaHpiEventLogEntryT LogEntry;
	SaHpiEventT EvtEntry;
	SaHpiEventLogInfoT info;
	SaHpiBoolT savedState;

	status = saHpiEventLogStateGet(session, resource, &savedState);
	if (status != SA_OK) {
		e_print(saHpiEventLogStateGet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}

	status = saHpiEventLogStateSet(session, resource, SAHPI_FALSE);
	if (status != SA_OK) {
		e_print(saHpiEventLogStateSet, SA_OK, status);
		return SAF_TEST_UNRESOLVED;
	}
	//
	//  Check to see if there needs to be an eventlog entry added.
	// 
	status = saHpiEventLogInfoGet(session, resource, &info);
	if (status != SA_OK) {
		// Even if this resource does not work, others will
		e_print(saHpiEventLogInfoGet, SA_OK, status);
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		if (info.Size == 0)
			retval = SAF_TEST_NOTSUPPORT;
		else {
			if (info.Entries == info.Size) {
				status = saHpiEventLogClear(session, resource);
				if (status != SA_OK) {
					e_print(saHpiEventLogClear, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}

			if (retval == SAF_TEST_UNKNOWN) {
				EvtEntry.EventType = SAHPI_ET_USER;
				EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
				EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
				EvtEntry.Severity = SAHPI_OK;
				strncpy(EvtEntry.EventDataUnion.UserEvent.
					UserEventData.Data, TEST_STRING,
					TEST_STRING_LENGTH);
				EvtEntry.EventDataUnion.UserEvent.UserEventData.
				    DataLength = TEST_STRING_LENGTH;
				EvtEntry.EventDataUnion.UserEvent.UserEventData.
				    Language = SAHPI_LANG_ENGLISH;
				EvtEntry.EventDataUnion.UserEvent.UserEventData.
				    DataType = SAHPI_TL_TYPE_TEXT;

				status = saHpiEventLogEntryAdd(session,
							       resource,
							       &EvtEntry);

				if (status == SA_ERR_HPI_INVALID_DATA) {
					retval = SAF_TEST_NOTSUPPORT;
				} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
					retval = SAF_TEST_NOTSUPPORT;
				} else if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiEventLogEntryAdd,
						SA_OK
						|| SA_ERR_HPI_INVALID_DATA,
						status);
				}
			}
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
			retval = SAF_TEST_FAIL;
		} else if (sameUserEvent(&EvtEntry, &LogEntry.Event))
			retval = SAF_TEST_PASS;
		else {
			m_print("Didn't get the same event that was added!");
			retval = SAF_TEST_FAIL;
		}

		status = saHpiEventLogClear(session, resource);
		if (status != SA_OK)
			e_print(saHpiEventLogClear, SA_OK, status);

		status = saHpiEventLogStateSet(session, resource, savedState);
		if (status != SA_OK)
			e_print(savedState, SA_OK, status);
	}

	return (retval);
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG)
		retval = test_res(session, rpt_entry.ResourceId);
	else			// This resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	// On each domain, test the domain event log.
	retval = test_res(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

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

	retval = process_all_domains(Test_Resource, NULL, Test_Domain);

	return (retval);
}

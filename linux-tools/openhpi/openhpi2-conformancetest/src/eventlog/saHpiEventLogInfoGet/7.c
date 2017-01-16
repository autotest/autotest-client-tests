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
 * Authors:
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogInfoGet
 * Description:
 *   Call saHpiEventLogInfoGet to get the eventlog size. Add 
 *   user event log entries to fill the eventlog to confirm 
 *   the size. Add one more entry to confirm the overflow.
 *   Confirm the size is constant.   
 *   Expected return:  call returns SA_OK and the eventlog does
 *   not overflow until the maximum number of entries is 
 *   reached.
 * Line:        P48-18:P48-18
 *
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

int size_test(SaHpiSessionIdT session, SaHpiResourceIdT resourceId)
{
	SaHpiEventLogInfoT info;
	SaErrorT status;
	SaHpiUint32T index, size;
	SaHpiEventT testevent;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiBoolT savedState;

	status = saHpiEventLogStateGet(session, resourceId, &savedState);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventLogStateGet, SA_OK, status);
	} else {
		status =
		    saHpiEventLogStateSet(session, resourceId, SAHPI_FALSE);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiEventLogStateSet, SA_OK, status);
		} else {

			status = saHpiEventLogInfoGet(session,
						      resourceId, &info);
			if (status != SA_OK) {
				e_print(saHpiEventLogInfoGet, SA_OK, status);
				retval = SAF_TEST_UNRESOLVED;
			} else {
				size = info.Size;
				//Event log exist, but is always empty 
				if (size == 0)
					retval = SAF_TEST_NOTSUPPORT;
			}

			// Clear the eventlog
			if (retval == SAF_TEST_UNKNOWN) {
				// Not only should this clear the event log,
				// but the overflow flag should be reset.
				status = saHpiEventLogClear(session,
							    resourceId);
				if (status != SA_OK) {
					// return a bad status if unable to clear.
					e_print(saHpiEventLogClear, SA_OK,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}
			// Fill up the eventlog
			if (retval == SAF_TEST_UNKNOWN) {
				testevent.EventType = SAHPI_ET_USER;
				testevent.Source =
				    SAHPI_UNSPECIFIED_RESOURCE_ID;
				testevent.Timestamp = SAHPI_TIME_UNSPECIFIED;
				testevent.Severity = SAHPI_OK;
				strncpy(testevent.EventDataUnion.UserEvent.
					UserEventData.Data, TEST_STRING,
					TEST_STRING_LENGTH);
				testevent.EventDataUnion.UserEvent.
				    UserEventData.DataLength =
				    TEST_STRING_LENGTH;
				testevent.EventDataUnion.UserEvent.
				    UserEventData.Language = SAHPI_LANG_ENGLISH;
				testevent.EventDataUnion.UserEvent.
				    UserEventData.DataType = SAHPI_TL_TYPE_TEXT;
				for (index = 0; index < info.Size; index++) {
					status = saHpiEventLogEntryAdd(session,
								       resourceId,
								       &testevent);
					if (status != SA_OK) {
						e_print(saHpiEventLogEntryAdd,
							SA_OK, status);
						retval = SAF_TEST_UNRESOLVED;
						break;
					}
				}
			}
			// test to make sure the eventlog is full
			if (retval == SAF_TEST_UNKNOWN) {

				status = saHpiEventLogInfoGet(session,
							      resourceId,
							      &info);
				if (status != SA_OK) {
					e_print(saHpiEventLogInfoGet,
						SA_OK, status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}
			// Size should be a constant
			if (retval == SAF_TEST_UNKNOWN) {
				if (size != info.Size) {
					m_print
					    ("\"saHpiEventLogInfoGet\": The event log size changed from %d to %d",
					     size, info.Size);
					retval = SAF_TEST_FAIL;
				}
			}
			// Number of entries should be the same as the size
			if (retval == SAF_TEST_UNKNOWN) {
				//Compare the number of active entries
				// to the size of the log
				if (info.Entries != info.Size) {
					//
					//  The event log did not fill up
					m_print
					    ("\"saHpiEventLogInfoGet\": The event log did not fill up!");
					m_print
					    ("The event log was set with %d events, but only has %d entries!",
					     info.Size, info.Entries);
					retval = SAF_TEST_FAIL;
				}
			}
			// Add another test to make sure the size is a maximum limit
			if (retval == SAF_TEST_UNKNOWN) {
				status = saHpiEventLogEntryAdd(session,
							       resourceId,
							       &testevent);
				if (!((status == SA_OK) ||
				      (status == SA_ERR_HPI_OUT_OF_SPACE))) {
					e_print(saHpiEventLogEntryAdd,
						SA_OK | SA_ERR_HPI_OUT_OF_SPACE,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}
			// compare make sure the size is a maximum limit
			if (retval == SAF_TEST_UNKNOWN) {
				status = saHpiEventLogInfoGet(session,
							      resourceId,
							      &info);
				if (status != SA_OK) {
					e_print(saHpiEventLogInfoGet,
						SA_OK, status);
					retval = SAF_TEST_UNRESOLVED;
				}
			}
			// Make sure size is not exceeded
			if (retval == SAF_TEST_UNKNOWN) {
				//Compare the number of active entries
				// to the size of the log
				if (info.Entries != info.Size) {
					//
					//  The event log filled beyond the size of the log
					m_print
					    ("\"saHpiEventLogInfoGet\": The event log size is greater then stated size!");
					m_print
					    ("The event log size is %d events, but has %d entries!",
					     info.Size, info.Entries);
					retval = SAF_TEST_FAIL;
				} else {
					// Event log size test passed
					retval = SAF_TEST_PASS;
				}
			}

			status = saHpiEventLogClear(session, resourceId);
			status =
			    saHpiEventLogStateSet(session, resourceId,
						  savedState);
		}
	}

	return retval;
}

int testcase_domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	// Test the domain event log
	retval = size_test(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

	return retval;
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG)
		retval = size_test(session, report.ResourceId);
	else {
		//Resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;
	}
	return retval;
}

int main()
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, NULL, testcase_domain);

	return retval;
}

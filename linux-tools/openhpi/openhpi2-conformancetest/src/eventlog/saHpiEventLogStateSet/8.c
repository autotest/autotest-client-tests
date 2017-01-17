/*
 * (C) Copyright IBM Corp. 2004, 2005
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
 *     Liang Daming <daming.liang@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogStateSet
 * Description:   
 *   creates a system event after the event log state has been disabled 
 *   and re-enabled, making sure that it is added to the log.
 * Line:        P57-22:P57-24
 *
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING "Test 8 - saHpiEventLogStateSet"
#define TEST_STRING_LENGTH (strlen(TEST_STRING))

SaHpiBoolT is_special_event(SaHpiEventLogEntryT * eventLogEntry)
{
	return (eventLogEntry->Event.EventType == SAHPI_ET_USER) &&
	    (eventLogEntry->Event.EventDataUnion.UserEvent.UserEventData.
	     DataLength == TEST_STRING_LENGTH)
	    &&
	    (!memcmp
	     (eventLogEntry->Event.EventDataUnion.UserEvent.UserEventData.Data,
	      TEST_STRING, TEST_STRING_LENGTH));
}

int find_event(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId)
{
	SaErrorT status;
	int retval = SAF_TEST_FAIL;
	SaHpiEventLogEntryIdT entryId;
	SaHpiEventLogEntryIdT nextEntryId;
	SaHpiEventLogEntryIdT prevEntryId;
	SaHpiEventLogEntryT eventLogEntry;

	prevEntryId = SAHPI_NEWEST_ENTRY;
	while (prevEntryId != SAHPI_NO_MORE_ENTRIES) {
		entryId = prevEntryId;
		status = saHpiEventLogEntryGet(sessionId, resourceId,
					       entryId,
					       &nextEntryId,
					       &prevEntryId,
					       &eventLogEntry, NULL, NULL);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			break;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiEventLogEntryGet, SA_OK, status);
			break;
		} else if (is_special_event(&eventLogEntry)) {
			retval = SAF_TEST_PASS;
			break;
		}
	}

	return retval;
}

int eventlog_test(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId)
{
	SaHpiEventLogInfoT info;
	SaErrorT status;
	SaHpiEventT event;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiBoolT eventLogState;

	status = saHpiEventLogInfoGet(sessionId, resourceId, &info);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventLogInfoGet, SA_OK, status);
	} else {
		if (info.Size == 0) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (info.Entries == info.Size) {
			retval = SAF_TEST_NOTSUPPORT;
		} else {
			status =
			    saHpiEventLogStateGet(sessionId, resourceId,
						  &eventLogState);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiEventLogStateGet, SA_OK, status);
			} else {
				status =
				    saHpiEventLogStateSet(sessionId, resourceId,
							  SAHPI_FALSE);
				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiEventLogStateSet, SA_OK,
						status);
				} else {
					status =
					    saHpiEventLogStateSet(sessionId,
								  resourceId,
								  SAHPI_TRUE);
					if (status != SA_OK) {
						retval = SAF_TEST_UNRESOLVED;
						e_print(saHpiEventLogStateSet,
							SA_OK, status);
					} else {
						event.Source =
						    SAHPI_UNSPECIFIED_RESOURCE_ID;
						event.EventType = SAHPI_ET_USER;
						event.Severity =
						    SAHPI_INFORMATIONAL;
						event.EventDataUnion.UserEvent.
						    UserEventData.DataType =
						    SAHPI_TL_TYPE_TEXT;
						event.EventDataUnion.UserEvent.
						    UserEventData.Language =
						    SAHPI_LANG_ENGLISH;
						event.EventDataUnion.UserEvent.
						    UserEventData.DataLength =
						    TEST_STRING_LENGTH;
						memcpy(event.EventDataUnion.
						       UserEvent.UserEventData.
						       Data, TEST_STRING,
						       TEST_STRING_LENGTH);

						status =
						    saHpiEventAdd(sessionId,
								  &event);

						if (status ==
						    SA_ERR_HPI_INVALID_DATA) {
							retval =
							    SAF_TEST_NOTSUPPORT;
						} else if (status != SA_OK) {
							retval =
							    SAF_TEST_UNRESOLVED;
							e_print(saHpiEventAdd,
								SA_OK, status);
						} else {
							sleep(5);	// wait for event to get to event log

							retval =
							    find_event
							    (sessionId,
							     resourceId);

							// restore state
							status =
							    saHpiEventLogStateSet
							    (sessionId,
							     resourceId,
							     eventLogState);
							if (status != SA_OK) {
								e_print
								    (saHpiEventLogStateSet,
								     SA_OK,
								     status);
							}
						}
					}
				}
			}
		}
	}

	return retval;
}

int testcase_domain(SaHpiSessionIdT session)
{
	return eventlog_test(session, SAHPI_UNSPECIFIED_RESOURCE_ID);
}

int main()
{
	return process_all_domains(NULL, NULL, testcase_domain);
}

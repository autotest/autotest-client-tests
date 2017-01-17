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
 * Author(s):
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventAdd
 * Description:  
 *      Add a user event then call saHpiEventLogEntryGet
 *      to see if the event is logged in the Domain Event log
 * Line:        P64-38:P64-38
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "saf_test.h"

SaHpiEventT new_event_1 = {
	.EventType = SAHPI_ET_USER,
	.Severity = SAHPI_CRITICAL,
	.Source = SAHPI_UNSPECIFIED_RESOURCE_ID,
	.Timestamp = SAHPI_TIME_UNSPECIFIED,
	.EventDataUnion = {
			   .UserEvent = {
					 .UserEventData = {
							   .DataType =
							   SAHPI_TL_TYPE_TEXT,
							   .Language =
							   SAHPI_LANG_ZULU,
							   .Data =
							   "event test1",
							   .DataLength = 11}
					 }
			   }
};

#define D_TIMEOUT 5000000000ll	/*5 seconds */

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaErrorT val;
	int ret = SAF_TEST_UNRESOLVED;
	SaHpiEventLogEntryIdT curr = SAHPI_NEWEST_ENTRY;
	SaHpiEventLogEntryIdT next, pre;
	SaHpiEventLogEntryT log;
	SaHpiBoolT enable = SAHPI_TRUE;

	val = saHpiEventLogClear(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
	if (val != SA_OK) {
		e_print(saHpiEventLogClear, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	val =
	    saHpiEventLogStateGet(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID,
				  &enable);
	if (val != SA_OK) {
		e_print(saHpiEventLogStateGet, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	if (!enable) {
		val =
		    saHpiEventLogStateSet(session_id,
					  SAHPI_UNSPECIFIED_RESOURCE_ID,
					  SAHPI_TRUE);
		if (val != SA_OK) {
			e_print(saHpiEventLogStateSet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}
	}
	// user events should clear the log before exiting
	val = saHpiEventLogClear(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
	if (val != SA_OK) {
		e_print(saHpiEventLogClear, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	val = saHpiEventAdd(session_id, &new_event_1);
	if (val != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}
	// pause for 5 seconds for event to make it to the event log.

	sleep(5);

	// go through the event log looking for our user event.  If we
	// don't find it, we will fail.

	pre = SAHPI_NEWEST_ENTRY;
	while (pre != SAHPI_NO_MORE_ENTRIES) {
		curr = pre;
		val =
		    saHpiEventLogEntryGet(session_id,
					  SAHPI_UNSPECIFIED_RESOURCE_ID, curr,
					  &pre, &next, &log, NULL, NULL);
		if (val == SA_ERR_HPI_NOT_PRESENT) {
			break;
		} else if (val != SA_OK) {
			e_print(saHpiEventGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			break;
		} else if ((log.Event.EventType == SAHPI_ET_USER) &&
			   (log.Event.EventDataUnion.UserEvent.UserEventData.
			    DataLength ==
			    new_event_1.EventDataUnion.UserEvent.UserEventData.
			    DataLength)
			   &&
			   (!memcmp
			    (log.Event.EventDataUnion.UserEvent.UserEventData.
			     Data,
			     new_event_1.EventDataUnion.UserEvent.UserEventData.
			     Data,
			     log.Event.EventDataUnion.UserEvent.UserEventData.
			     DataLength))) {
			ret = SAF_TEST_PASS;
			break;
		}
	}

	if (ret == SAF_TEST_UNKNOWN) {
		ret = SAF_TEST_FAIL;
		m_print("Event was not found in Event Log!");
	}

      out:
	if (!enable) {
		val =
		    saHpiEventLogStateSet(session_id,
					  SAHPI_UNSPECIFIED_RESOURCE_ID,
					  enable);
		if (val != SA_OK) {
			e_print(saHpiEventLogStateSet, SA_OK, val);
		}
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNRESOLVED;

	if (D_TIMEOUT == SAHPI_TIMEOUT_IMMEDIATE)
		return SAF_TEST_UNRESOLVED;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

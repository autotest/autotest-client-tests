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
 *      Wang Jing <jing.j.wang@intel.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Qun Li <qun.li@intel.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiUnsubscribe
 * Description:
 *   Check whether events queue will be cleared after unsubsciription
 * Line:        P61-14:P61-15
 */
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include "saf_test.h"

#define PAUSE_TIME 5		/* 5 seconds */
#define D_TIMEOUT 5000000000ll	/*5 seconds */

SaHpiEventT new_event_1 = {
	.EventType = SAHPI_ET_USER,
	.Severity = SAHPI_INFORMATIONAL,
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

SaHpiEventT new_event_2 = {
	.EventType = SAHPI_ET_USER,
	.Severity = SAHPI_OK,
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
							   "event test2",
							   .DataLength = 11}
					 }
			   }
};

/*********************************************************************
 *
 * Determine if two events are the same or not.
 *
 *********************************************************************/

SaHpiBoolT sameEvent(SaHpiEventT * e1, SaHpiEventT * e2)
{
	SaHpiBoolT same = SAHPI_TRUE;

	if (e1->EventType != e2->EventType) {
		same = SAHPI_FALSE;
	} else if (e1->EventDataUnion.UserEvent.UserEventData.DataLength !=
		   e2->EventDataUnion.UserEvent.UserEventData.DataLength) {
		same = SAHPI_FALSE;
	} else if (memcmp(e1->EventDataUnion.UserEvent.UserEventData.Data,
			  e2->EventDataUnion.UserEvent.UserEventData.Data,
			  e1->EventDataUnion.UserEvent.UserEventData.
			  DataLength)) {
		same = SAHPI_FALSE;
	}

	return same;
}

int process_session_event(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;
	int found1 = 0, found2 = 0;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto fun_out;
	}

	val = saHpiEventAdd(session_id, &new_event_1);
	if (val != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto fun_out1;
	}

	val = saHpiEventAdd(session_id, &new_event_2);
	if (val != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto fun_out1;
	}

	/* Wait for the events to actually show up in the event queue 
	 * before we unsubscribe. */
	sleep(PAUSE_TIME);

	val = saHpiUnsubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiUnsubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	}
	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	}

	found1 = SAHPI_FALSE;
	found2 = SAHPI_FALSE;
	while (1) {
		val =
		    saHpiEventGet(session_id, D_TIMEOUT, &event, &rdr,
				  &rpt_entry, NULL);
		if (val != SA_OK && val != SA_ERR_HPI_TIMEOUT) {
			e_print(saHpiEventGet, SA_OK
				|| SA_ERR_HPI_TIMEOUT, val);
			ret = SAF_TEST_UNRESOLVED;
			goto fun_out1;
		}

		if (val == SA_ERR_HPI_TIMEOUT)
			break;

		if (sameEvent(&event, &new_event_1)) {
			found1 = SAHPI_TRUE;
		} else if (sameEvent(&event, &new_event_2)) {
			found2 = SAHPI_TRUE;
		}
	}

	if (found1 || found2) {
		m_print("Unsubscripton Failed: found1=%d, found2=%d", found1,
			found2);
		ret = SAF_TEST_FAIL;
	}
	//user events should clear the log before exiting
	val = saHpiEventLogClear(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
	if (val != SA_OK)
		e_print(saHpiEventLogClear, SA_OK, val);

      fun_out1:
	val = saHpiUnsubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiUnsubscribe, SA_OK, val);
	}

      fun_out:
	if (ret == SAF_TEST_UNKNOWN)
		ret = SAF_TEST_PASS;
	return ret;

}

int main()
{
	int ret = SAF_TEST_UNRESOLVED;
	SaErrorT rv = SA_OK;
	SaHpiSessionIdT sessionid;
	rv = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sessionid, NULL);
	if (rv != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, rv);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}
	ret = process_session_event(sessionid);
// out1:        
	rv = saHpiSessionClose(sessionid);
	if (rv != SA_OK) {
		e_print(saHpiSessionClose, SA_OK, rv);
	}

      out:
	return ret;
}

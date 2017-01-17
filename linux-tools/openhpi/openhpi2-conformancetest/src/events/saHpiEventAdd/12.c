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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventAdd
 * Description:
 *   Open two sessions for the same domain and verify
 *   that an event added in one session is published
 *   to both sessions.
 * Line:        P64-36:P64-37
 */
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include "saf_test.h"

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

SaErrorT findEvent(SaHpiSessionIdT sessionId, SaHpiEventT * event,
		   SaHpiBoolT * found)
{
	SaErrorT status = SA_OK;
	SaHpiEventT e;

	*found = SAHPI_FALSE;
	while (!(*found) && status == SA_OK) {
		status =
		    saHpiEventGet(sessionId, D_TIMEOUT, &e, NULL, NULL, NULL);
		if (status == SA_OK) {
			*found = sameEvent(event, &e);
		} else if (status != SA_ERR_HPI_TIMEOUT) {
			e_print(saHpiEventGet, SA_OK, status);
		}
	}

	// For a timeout, found will be set to false.
	// Therefore, return OK to indicate that nothing abnormal happened.

	if (status == SA_ERR_HPI_TIMEOUT) {
		status = SA_OK;
	}

	return status;
}

SaErrorT openSession(SaHpiSessionIdT * sessionId)
{
	SaErrorT status;

	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, sessionId, NULL);
	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
	}
	return status;
}

SaErrorT closeSession(SaHpiSessionIdT sessionId)
{
	SaErrorT status;

	status = saHpiSessionClose(sessionId);
	if (status != SA_OK) {
		e_print(saHpiSessionClose, SA_OK, status);
	}
	return status;
}

SaErrorT subscribe(SaHpiSessionIdT sessionId)
{
	SaErrorT status;

	status = saHpiSubscribe(sessionId);
	if (status != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, status);
	}
	return status;
}

SaErrorT unsubscribe(SaHpiSessionIdT sessionId)
{
	SaErrorT status;

	status = saHpiUnsubscribe(sessionId);
	if (status != SA_OK) {
		e_print(saHpiUnsubscribe, SA_OK, status);
	}
	return status;
}

int run_test(SaHpiSessionIdT sessionId1, SaHpiSessionIdT sessionId2)
{
	int ret;
	SaErrorT status;
	SaHpiBoolT found;

	status = saHpiEventAdd(sessionId1, &new_event_1);
	if (status != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		status = findEvent(sessionId1, &new_event_1, &found);
		if (status != SA_OK) {
			ret = SAF_TEST_UNRESOLVED;
		} else if (!found) {
			ret = SAF_TEST_FAIL;
			m_print("Could not find event in first session!");
		} else {
			status = findEvent(sessionId2, &new_event_1, &found);
			if (status != SA_OK) {
				ret = SAF_TEST_UNRESOLVED;
			} else if (!found) {
				ret = SAF_TEST_FAIL;
				m_print
				    ("Could not find event in second session!");
			} else {
				ret = SAF_TEST_PASS;
			}
		}

		//user events should clear the log before exiting
		status =
		    saHpiEventLogClear(sessionId1,
				       SAHPI_UNSPECIFIED_RESOURCE_ID);
		if (status != SA_OK)
			e_print(saHpiEventLogClear, SA_OK, status);
	}

	return ret;
}

/*********************************************************************
 *
 * Main Program.  Open and subscribe for events for two sessions.
 * Then run the above test.
 *
 * *******************************************************************/
int main()
{
	int ret = SAF_TEST_UNRESOLVED;
	SaHpiSessionIdT sessionId1;
	SaHpiSessionIdT sessionId2;

	if (openSession(&sessionId1) != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
	} else {
		if (openSession(&sessionId2) != SA_OK) {
			ret = SAF_TEST_UNRESOLVED;
		} else {
			if (subscribe(sessionId1) != SA_OK) {
				ret = SAF_TEST_UNRESOLVED;
			} else {
				if (subscribe(sessionId2) != SA_OK) {
					ret = SAF_TEST_UNRESOLVED;
				} else {
					ret = run_test(sessionId1, sessionId2);
					unsubscribe(sessionId2);
				}
				unsubscribe(sessionId1);
			}
			closeSession(sessionId2);
		}
		closeSession(sessionId1);
	}

	return ret;
}

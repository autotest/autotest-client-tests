/*
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
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:
 *      Verify that the ResourceCapabilities is set to zero
 *      when a user event is retrieved from the event queue.
 * Line:        P63-8:P63-10
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TIMEOUT  10000000000LL	/* 10 seconds */

/*********************************************************************
 *
 * New User Event to be added to the domain.
 *
 * *******************************************************************/

SaHpiEventT new_user_event = {
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
							   .Data = "event test",
							   .DataLength = 10}
					 }
			   }
};

/*********************************************************************
 *
 * Determine if two events are the same or not.
 *
 * *******************************************************************/

SaHpiBoolT sameUserEvent(SaHpiEventT * e1, SaHpiEventT * e2)
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

/*********************************************************************
 *
 * Test a Domain.
 *
 * *******************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		val = saHpiEventAdd(session_id, &new_user_event);
		if (val != SA_OK) {
			e_print(saHpiEventAdd, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
		} else {
			/* Notice that if we don't find the event that we added,
			 * then a timeout will eventually occur which will result
			 * in UNRESOLVED being returned. */

			while (ret == SAF_TEST_UNKNOWN) {
				val =
				    saHpiEventGet(session_id, TIMEOUT, &event,
						  &rdr, &rpt_entry, NULL);
				if (val != SA_OK) {
					e_print(saHpiEventGet, SA_OK, val);
					ret = SAF_TEST_UNRESOLVED;
				} else
				    if (sameUserEvent(&event, &new_user_event))
				{
					if (rpt_entry.ResourceCapabilities == 0) {
						ret = SAF_TEST_PASS;
					} else {
						ret = SAF_TEST_FAIL;
						m_print
						    ("Resource Capabilities is not zero!");
					}
				}
			}

			// user events should clear the log before exiting
			val =
			    saHpiEventLogClear(session_id,
					       SAHPI_UNSPECIFIED_RESOURCE_ID);
			if (val != SA_OK)
				e_print(saHpiEventLogClear, SA_OK, val);
		}

		val = saHpiUnsubscribe(session_id);
		if (val != SA_OK) {
			e_print(saHpiUnsubscribe, SA_OK, val);
		}
	}

	return ret;
}

/*********************************************************************
 *
 * Main Program.
 *
 * *******************************************************************/

int main()
{
	return process_all_domains(NULL, NULL, Test_Domain);
}

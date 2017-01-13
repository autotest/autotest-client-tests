/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 * Copyright (c) 2005, University of New Hamphsire
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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:  
 *      Call the function with SAHPI_TIMEOUT_IMMEDIATE when
 *      the event queue is empty.
 *      Expected return: SA_ERR_HPI_TIMEOUT.
 * Line:        P62-33:P62-34
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "saf_test.h"

#define MAX_EVENTS 100
#define PAUSE_TIME   5		/* seconds */

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
							   SAHPI_LANG_ENGLISH,
							   .Data = "event test",
							   .DataLength = 10}
					 }
			   }
};

/*********************************************************************
 *
 * Test a domain.
 *
 * This test must verify that SA_ERR_HPI_TIMEOUT is returned if and
 * only if the event queue is empty.  So, if TIMEOUT is returned, how
 * do we know that the event queue really is empty?  There is no
 * perfect answer to this.  To do the best we can, this test first adds
 * an event to the event queue.  Therefore, we should get one or more
 * SA_OKs returned.  If we get a TIMEOUT without seeing an SA_OK, then
 * things are not working properly.  If we do get some SA_OKs and then
 * get a TIMEOUT, we can assume that queue is indeed empty and that
 * things are working properly.
 *
 * To avoid the situation were the function always returns SA_OK even
 * when the queue is empty, we will stop getting events after we have 
 * retrieved 100 events.
 *
 * *******************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;
	int ok_cnt = 0;

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
			// wait for the event to be added to the event queue
			sleep(PAUSE_TIME);

			while ((ok_cnt < MAX_EVENTS)
			       && (ret == SAF_TEST_UNKNOWN)) {
				val =
				    saHpiEventGet(session_id,
						  SAHPI_TIMEOUT_IMMEDIATE,
						  &event, NULL, NULL, NULL);

				if (val == SA_OK) {
					ok_cnt++;
				} else if (val == SA_ERR_HPI_TIMEOUT) {
					if (ok_cnt == 0) {
						e_print(saHpiEventGet,
							ok_cnt > 0, val);
						ret = SAF_TEST_FAIL;
					} else {
						ret = SAF_TEST_PASS;
					}
				} else {
					e_print(saHpiEventGet, SA_OK
						|| SA_ERR_HPI_TIMEOUT, val);
					ret = SAF_TEST_UNRESOLVED;
				}
			}

			//user events should clear the log before exiting
			val =
			    saHpiEventLogClear(session_id,
					       SAHPI_UNSPECIFIED_RESOURCE_ID);
			if (val != SA_OK)
				e_print(saHpiEventLogClear, SA_OK, val);

			if (ret == SAF_TEST_UNKNOWN) {
				ret = SAF_TEST_FAIL;
				printf
				    ("  Did not get SA_ERR_HPI_TIMEOUT as expected!\n");
			}
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

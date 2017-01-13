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
 *     Qun Li <qun.li@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:  
 *      Add a user event
 *      Call the function to get this event
 *      See if Rdr->RdrType is set to SAHPI_NO_RECORD
 * Line:        P63-11:P63-13
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

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

/*********************************************************************
 *
 * Determine if two events are the same or not.
 *
 * *******************************************************************/

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

#define TIMEOUT  2000000000LL	/*2 seconds */
int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	int ret = SAF_TEST_UNRESOLVED;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	val = saHpiEventAdd(session_id, &new_event_1);
	if (val != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out1;
	}

	/* skip over events until we found the one we added */

	while (1) {
		val =
		    saHpiEventGet(session_id, SAHPI_TIMEOUT_BLOCK, &event, &rdr,
				  &rpt_entry, NULL);
		if (val != SA_OK) {
			e_print(saHpiEventGet, SA_OK
				|| SA_ERR_HPI_TIMEOUT, val);
			ret = SAF_TEST_UNRESOLVED;
			break;
		} else {
			if (sameEvent(&event, &new_event_1)) {
				if (rdr.RdrType != SAHPI_NO_RECORD)
					ret = SAF_TEST_FAIL;
				else
					ret = SAF_TEST_PASS;

				break;
			}
		}
	}

	//user events should clear the log before exiting
	val = saHpiEventLogClear(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
	if (val != SA_OK)
		e_print(saHpiEventLogClear, SA_OK, val);

      out1:
	val = saHpiUnsubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiUnsubscribe, SA_OK, val);
	}

      out:
	return ret;
}

int main()
{
	int ret = SAF_TEST_UNRESOLVED;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

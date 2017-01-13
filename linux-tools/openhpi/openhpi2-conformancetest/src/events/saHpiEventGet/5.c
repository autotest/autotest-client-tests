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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Xiaowei Yang <xiaowei.yang@intel.com>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description:   
 *      Call the function passing SAHPI_TIMEOUT_IMMEDIATE
 * Line:        P62-16:P62-17
 */
#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
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

int main()
{
	SaHpiSessionIdT session_id;
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session_id, NULL);
	if (val != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
		e_print(saHpiSessionOpen, SA_OK, val);
		goto out1;
	}
	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
		e_print(saHpiSubscribe, SA_OK, val);
		goto out2;
	}

	val = saHpiEventAdd(session_id, &new_event_1);
	if (val != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventAdd, SA_OK, val);
		goto out3;
	}

	sleep(5);

	val = saHpiEventGet(session_id, SAHPI_TIMEOUT_IMMEDIATE,
			    &event, &rdr, &rpt_entry, NULL);

	if (val != SA_OK) {
		e_print(saHpiEventGet, SA_OK, val);
		ret = SAF_TEST_FAIL;
	} else {
		ret = SAF_TEST_PASS;
	}

	//user events should clear the log before exiting
	val = saHpiEventLogClear(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID);
	if (val != SA_OK)
		e_print(saHpiEventLogClear, SA_OK, val);
      out3:
	val = saHpiUnsubscribe(session_id);

      out2:
	val = saHpiSessionClose(session_id);
      out1:

	return ret;
}

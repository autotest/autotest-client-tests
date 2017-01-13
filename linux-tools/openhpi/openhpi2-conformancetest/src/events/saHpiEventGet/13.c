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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventGet
 * Description: 
 *      Add an event to queue.
 *      Call the function passing TIMEOUT to Timeout
 *      Check if the function return immediately 
 * Line:        P63-1:P63-2
 */
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include "saf_test.h"

#define TIMEOUT  6000000000LL	/*6 seconds */
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

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;
	SaErrorT val;
	struct timeval tv1, tv2;
	SaHpiTimeT duration;
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

	gettimeofday(&tv1, NULL);
	val =
	    saHpiEventGet(session_id, TIMEOUT, &event, &rdr, &rpt_entry, NULL);
	if (val != SA_OK) {
		e_print(saHpiEventGet, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out1;
	}
	gettimeofday(&tv2, NULL);
	duration = (tv2.tv_sec - tv1.tv_sec);
	if (duration <= 4) {
		ret = SAF_TEST_PASS;
	} else {
		m_print
		    ("Did not return immediately, actually it take %lld sec\n",
		     duration);
		ret = SAF_TEST_FAIL;
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

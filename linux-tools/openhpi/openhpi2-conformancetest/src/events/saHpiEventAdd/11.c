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
 * Function:    saHpiEventAdd
 * Description:  
 *      Add a user event whose data surpasses the maximum data length.
 *      Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P64-28:P64-29
 */
#include <stdio.h>
#include <stdlib.h>
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
							   }
					 }
			   }
};

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaErrorT val;
	int ret = SAF_TEST_UNRESOLVED;
	SaHpiEventLogInfoT info;
	SaHpiUint32T len;

	val =
	    saHpiEventLogInfoGet(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID,
				 &info);
	if (val != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventLogInfoGet, SA_OK, val);
	} else if (info.UserEventMaxSize >= SAHPI_MAX_TEXT_BUFFER_LENGTH) {
		ret = SAF_TEST_NOTSUPPORT;
	} else {
		new_event_1.EventDataUnion.UserEvent.UserEventData.DataLength =
		    SAHPI_MAX_TEXT_BUFFER_LENGTH;

		val = saHpiEventAdd(session_id, &new_event_1);
		if (val != SA_ERR_HPI_INVALID_DATA) {
			e_print(saHpiEventAdd, SA_ERR_HPI_INVALID_DATA, val);
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNRESOLVED;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

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
 *      No valid RPT entry will have a zero ResourceCapabilities.
 *      User will need to manually insert a FRU.
 * Line:        P63-10:P63-10
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

#define TIMEOUT  2000000000LL	/*2 seconds */
#define RANGE     500000000LL	/*0.5 secdons */

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry, rpt_entry2;
	SaErrorT val;
	int ret = SAF_TEST_UNRESOLVED;

	val = saHpiSubscribe(session_id);
	if (val != SA_OK) {
		e_print(saHpiSubscribe, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	read_prompt("Please insert a FRU in the domain.\n"
		    "Then press Enter to continue ...\n");

	while (1) {
		val =
		    saHpiEventGet(session_id, TIMEOUT, &event, &rdr, &rpt_entry,
				  NULL);
		if (val != SA_OK) {
			e_print(saHpiEventGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		if ((event.EventType == SAHPI_ET_HOTSWAP) && 
			(event.EventDataUnion.HotSwapEvent.HotSwapState != SAHPI_HS_STATE_NOT_PRESENT)) {

			if (rpt_entry.ResourceCapabilities == 0) {
				ret = SAF_TEST_FAIL;
				m_print("Resource Capabilities is zero!");
			} else {
				/* make sure that the ResourceId is valid */
				val = saHpiRptEntryGetByResourceId(session_id,
								   rpt_entry.
								   ResourceId,
								   &rpt_entry2);
				if (val == SA_OK) {
					if (rpt_entry2.EntryId ==
					    rpt_entry.EntryId) {
						ret = SAF_TEST_PASS;
					} else {
						ret = SAF_TEST_FAIL;
						m_print
						    ("Rpt Entries have different Entry Ids!");
					}
				} else {
					ret = SAF_TEST_FAIL;
					e_print(saHpiRptEntryGetByResourceId,
						SA_OK, val);
				}
			}
			goto out1;
		}
	}

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

	if (TIMEOUT == SAHPI_TIMEOUT_IMMEDIATE) {
		return SAF_TEST_UNRESOLVED;
	}
	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

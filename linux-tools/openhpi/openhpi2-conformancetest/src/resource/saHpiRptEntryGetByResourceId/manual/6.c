/* Copyright IBM Corp. 2004, 2005
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
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiRptEntryGetByResourceId
 * Description:
 *   Call saHpiRptEntryGetByResourceId with a ResourceId from hotswap extraction event
 *   User need plug out a FRU manually
 * Line:        P42-25:42-26
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

#define TIMEOUT 5000000000ll
#define TIMES   20

int main()
{
	SaHpiSessionIdT sid;
	SaHpiEventT event;
	SaHpiRptEntryT rpt_entry, rpt_entry2;
	int i;

	SaErrorT status;
	int ret = SAF_TEST_UNKNOWN;

    printf("\n*****************Domain func begin***************\n");

	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sid, NULL);
	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		status = saHpiSubscribe(sid);
		if (status != SA_OK) {
			e_print(saHpiSubscribe, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
		} else {
			read_prompt
			    ("Now pls. plug out a FRU in the domain ...\n"
			     "Then press Enter key to continue ...\n");

			/* We only wait a decent interval for the events */
			for (i = 0; i < TIMES;) {
				status =
				    saHpiEventGet(sid, TIMEOUT, &event, NULL,
						  &rpt_entry, NULL);

				if (status == SA_ERR_HPI_TIMEOUT)
					i++;
				else if (status != SA_OK) {
					e_print(saHpiEventGet, SA_OK, status);
					ret = SAF_TEST_UNRESOLVED;

					break;
				} else if (event.EventType == SAHPI_ET_HOTSWAP
					   && event.EventDataUnion.HotSwapEvent.
					   HotSwapState ==
					   SAHPI_HS_STATE_NOT_PRESENT) {
					status =
					    saHpiRptEntryGetByResourceId(sid,
									 rpt_entry.
									 ResourceId,
									 &rpt_entry2);

					if (status !=
					    SA_ERR_HPI_INVALID_RESOURCE) {
						e_print
						    (saHpiRptEntryGetByResourceId,
						     SA_ERR_HPI_INVALID_RESOURCE,
						     status);
						ret = SAF_TEST_FAIL;
					} else
						ret = SAF_TEST_PASS;

					break;
				}
			}

			if (ret == SAF_TEST_UNKNOWN) {
				ret = SAF_TEST_UNRESOLVED;
			}

			status = saHpiUnsubscribe(sid);
		}
		status = saHpiSessionClose(sid);
	}

	printf("\n  return=%s\n",get_test_result(ret));
	printf("\n*****************Domain func end*****************\n");

	return ret;
}



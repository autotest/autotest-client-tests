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
 * Function:    saHpiDiscover
 * Description:
 *   Check if saHpiResourceSeveritySet takes effect
 *   User needs insert/extract a FRU manually
 * Line:        P43-2:43-6
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
	SaHpiRptEntryT rpt_entry;
	SaHpiResourceIdT rid;
	SaHpiSeverityT severity_old, severity_new;
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
			/* User inserts a FRU manually */
			read_prompt("Now pls. insert a FRU in the domain ...\n"
				    "Then press Enter key to continue ...\n");

			for (i = 0;;) {
				status =
				    saHpiEventGet(sid, TIMEOUT, &event, NULL,
						  &rpt_entry, NULL);

				if (status == SA_ERR_HPI_TIMEOUT
				    && ++i == TIMES) {
					m_print
					    ("The timeout value has been reached, but the user did not enter an FRU.");
					ret = SAF_TEST_UNRESOLVED;
					break;
				} else if (status != SA_OK) {
					e_print(saHpiEventGet, SA_OK, status);
					ret = SAF_TEST_UNRESOLVED;
					break;
				} else if ((event.EventType == SAHPI_ET_HOTSWAP) &&
					       ((event.EventDataUnion.HotSwapEvent.HotSwapState == SAHPI_HS_STATE_ACTIVE) ||
					        (event.EventDataUnion.HotSwapEvent.HotSwapState == SAHPI_HS_STATE_INSERTION_PENDING))) {
					rid = rpt_entry.ResourceId;
					severity_old = rpt_entry.ResourceSeverity;
					break;
				}
			}

			if (ret == SAF_TEST_UNKNOWN) {

				if (severity_old != SAHPI_CRITICAL)
					severity_new = SAHPI_CRITICAL;
				else
					severity_new = SAHPI_MAJOR;

				status = saHpiResourceSeveritySet(sid, rid, severity_new);

				if (status != SA_OK) {
					e_print(saHpiResourceSeveritySet, SA_OK, status);
					ret = SAF_TEST_UNRESOLVED;
				} else {

					read_prompt
					    ("Now please create a \"surprise extraction\" by removing the\n"
						 "the same FRU you just inserted to identify its ResourceId ...\n"
					     "Then press the Enter key to continue ...\n");

					for (i = 0;;) {
						status = saHpiEventGet(sid, TIMEOUT, &event, NULL,
								               &rpt_entry, NULL);

						if (status == SA_ERR_HPI_TIMEOUT) {
							if (++i == TIMES) {
								m_print
							   	 ("The timeout value has been reached, but the user did not plug out an FRU.");
								ret = SAF_TEST_UNRESOLVED;
								break;
							}
						} else if (status != SA_OK) {
							e_print(saHpiEventGet, SA_OK, status);
							ret = SAF_TEST_UNRESOLVED;
							break;
						} else if (event.EventType == SAHPI_ET_HOTSWAP && 
								   event.EventDataUnion.HotSwapEvent.HotSwapState == SAHPI_HS_STATE_NOT_PRESENT &&
								   rpt_entry.ResourceId == rid && event.Severity == severity_new) {
							ret = SAF_TEST_PASS;
							break;
						}
					}
				}

				if (ret == SAF_TEST_UNKNOWN) {
					ret = SAF_TEST_FAIL;
				}

				saHpiResourceSeveritySet(sid, rid, severity_old);
			}

			status = saHpiUnsubscribe(sid);
		}

		status = saHpiSessionClose(sid);
	}

	printf("\n  return=%s\n",get_test_result(ret));
	printf("\n*****************Domain func end*****************\n");

	return ret;
}

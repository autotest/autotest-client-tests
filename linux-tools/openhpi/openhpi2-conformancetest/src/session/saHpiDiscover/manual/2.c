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
 *   Check whether RPT updates after calling discovery
 *   User need insert a FRU manually
 * Line:        P35-2:P35-7
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int main()
{
	SaHpiSessionIdT sid;
	SaHpiEntryIdT eid, next_eid;
	SaHpiRptEntryT rpt_entry;
	int i, j;

	SaErrorT status;
	int ret;

    printf("\n*****************Domain func begin***************\n");

	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sid, NULL);
	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
		goto out1;
	}

	status = saHpiDiscover(sid);
	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
		goto out2;
	}

	/* Count how many entries before insertion */
	for (i = 0, eid = SAHPI_FIRST_ENTRY; next_eid != SAHPI_LAST_ENTRY;
	     eid = next_eid, i++) {
		status = saHpiRptEntryGet(sid, eid, &next_eid, &rpt_entry);

		if ((status == SA_ERR_HPI_NOT_PRESENT
		     && eid != SAHPI_FIRST_ENTRY)
		    || (status != SA_OK && status != SA_ERR_HPI_NOT_PRESENT)) {
			e_print(saHpiRptEntryGet, SA_OK
				|| SA_ERR_HPI_NOT_PRESENT, status);
			ret = SAF_TEST_UNRESOLVED;
			goto out2;
		}
	}

	/* User inserts a FRU manually */
	read_prompt("Now pls. insert a FRU in the domain ...\n"
		    "Then press Enter key to continue ...\n");

	/* Run Discover again to make sure RPT is updated */
	status = saHpiDiscover(sid);
	if (status != SA_OK) {
		e_print(saHpiDiscover, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
		goto out2;
	}

	/* Count how many entries after insertion */
	for (j = 0, eid = next_eid = SAHPI_FIRST_ENTRY;
	     next_eid != SAHPI_LAST_ENTRY; eid = next_eid, j++) {
		status = saHpiRptEntryGet(sid, eid, &next_eid, &rpt_entry);

		if ((status == SA_ERR_HPI_NOT_PRESENT
		     && eid != SAHPI_FIRST_ENTRY)
		    || (status != SA_OK && status != SA_ERR_HPI_NOT_PRESENT)) {
			e_print(saHpiRptEntryGet, SA_OK
				|| SA_ERR_HPI_NOT_PRESENT, status);
			ret = SAF_TEST_UNRESOLVED;
			goto out2;
		}
	}

	/* We assume #entry change is due to our insertion */
	if (i + 1 == j)
		ret = SAF_TEST_PASS;
	else {
		m_print("Test failed: the number of entries after the ");
		m_print("insertion is not equal to one plus the number ");
		m_print("of entries before the insertion.");
		ret = SAF_TEST_FAIL;
	}

      out2:
	status = saHpiSessionClose(sid);
      out1:

	printf("\n  return=%s\n",get_test_result(ret));
	printf("\n*****************Domain func end*****************\n");

	return ret;
}



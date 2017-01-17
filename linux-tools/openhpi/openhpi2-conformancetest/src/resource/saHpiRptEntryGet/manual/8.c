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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiRptEntryGet
 * Description:
 *   Check whether RptUpdateCount is updated if we insert a FRU
 *   User need insert a FRU manually
 * Line:        P41-4:P41-8
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int main()
{
	SaHpiSessionIdT sid;
	SaHpiDomainInfoT dinfo;
	SaHpiUint32T c1, c2;
	SaErrorT status;
	int ret;

    printf("\n*****************Domain func begin***************\n");

	status = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sid, NULL);

	if (status != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, status);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		/* Get RPT update count before insertion */
		status = saHpiDomainInfoGet(sid, &dinfo);

		if (status != SA_OK) {
			e_print(saHpiDomainInfoGet, SA_OK, status);
			ret = SAF_TEST_UNRESOLVED;
		} else {
			c1 = dinfo.RptUpdateCount;

			/* User inserts a FRU manually */
			read_prompt("Now pls. insert a FRU in the domain and wait a short period for the Resource Table to be updated..."
				    "Then press Enter key to continue ...");

			/* Get RPT update count after insertion */
			status = saHpiDomainInfoGet(sid, &dinfo);

			if (status != SA_OK) {
				e_print(saHpiDomainInfoGet, SA_OK, status);
				ret = SAF_TEST_UNRESOLVED;
			} else {
				c2 = dinfo.RptUpdateCount;

				if (c1 == c2) {
					m_print
					    ("The RPT update count after the insertion of the ");
					m_print
					    ("FRU is the same as it was before the FRU was ");
					m_print
					    ("inserted. RptUpdateCount should have been updated ");
					m_print("after the FRU was inserted!");
					ret = SAF_TEST_FAIL;
				} else
					ret = SAF_TEST_PASS;
			}
		}

		status = saHpiSessionClose(sid);

		if (status != SA_OK) {
			e_print(saHpiSessionClose, SA_OK, status);
		}
	}

	printf("\n  return=%s\n",get_test_result(ret));
	printf("\n*****************Domain func end*****************\n");

	return ret;
}



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
 *      Wang Jing <jing.j.wang@intel.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiUnsubscribe
 * Description:
 *   Check whether saHpiEventGet can get events before subscription.
 * Line:        P62-28:P62-28
 */

#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include "saf_test.h"

#define D_TIMEOUT 5000000000ll	/*5 seconds */

int main()
{
	int ret = SAF_TEST_UNRESOLVED;
	SaHpiEventT event;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry;

	SaErrorT rv = SA_OK;
	SaHpiSessionIdT sessionid;
	rv = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &sessionid, NULL);
	if (rv != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, rv);
		ret = SAF_TEST_UNRESOLVED;
		goto out;
	}

	rv = saHpiEventGet(sessionid, D_TIMEOUT, &event, &rdr, &rpt_entry,
			   NULL);
	if (rv != SA_ERR_HPI_INVALID_REQUEST) {
		e_print(saHpiEventGet, SA_ERR_HPI_INVALID_REQUEST, rv);
		ret = SAF_TEST_FAIL;
	} else
		ret = SAF_TEST_PASS;

	rv = saHpiSessionClose(sessionid);
	if (rv != SA_OK) {
		e_print(saHpiSessionClose, SA_OK, rv);
	}

      out:
	return ret;
}

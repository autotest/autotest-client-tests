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
 * Function:    saHpiSubscribe
 * Description:   
 *      Call the function twice.
 *      saHpiSubscribe() returns SA_ERR_HPI_DUPLICATE.
 * Line:        P60-12:P60-12
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   events test -- saHpiSubscribe/5.c
*
*************************************************************/
int main()
{
	SaHpiSessionIdT session_id;
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

	val = saHpiSubscribe(session_id);
	if (val != SA_ERR_HPI_DUPLICATE) {
		e_print(saHpiSubscribe, SA_ERR_HPI_DUPLICATE, val);
		ret = SAF_TEST_FAIL;
	} else {
		ret = SAF_TEST_PASS;
	}

	val = saHpiUnsubscribe(session_id);

      out2:
	val = saHpiSessionClose(session_id);

      out1:

	return ret;
}

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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiSessionOpen
 * Description:   
 *   Open a new session when the DomainId does not exists.
 *   Expected return:  SA_ERR_HPI_INVALID_DOMAIN.
 * Line:        P33-18:P33-18
 */
#include <stdio.h>
#include "saf_test.h"

#define UNLIKELY_DOMAIN_ID 0xDEADBEEF

int main()
{
	SaHpiSessionIdT session_id;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiSessionOpen(UNLIKELY_DOMAIN_ID, &session_id, NULL);
	if (val != SA_ERR_HPI_INVALID_DOMAIN) {
		e_print(saHpiSessionOpen, SA_ERR_HPI_INVALID_DOMAIN, val);
		ret = SAF_TEST_FAIL;
	} else
		ret = SAF_TEST_PASS;

	if (val == SA_OK) {
		val = saHpiSessionClose(session_id);
	}

	return ret;
}

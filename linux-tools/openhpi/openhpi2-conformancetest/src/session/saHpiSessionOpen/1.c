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
 *   Open a new session with the DomainId equal to SAHPI_UNSPECIFIED_DOMAIN_ID.
 *   Expected return: SA_OK.
 * Line:        P33-10:P33-11
 */
#include <stdio.h>
#include "saf_test.h"

/******************************************************************************
*
*   Open a new session with the DomainId equal to SAHPI_UNSPECIFIED_DOMAIN_ID.
*
*   Expected return:  saHpiSessionOpen() returns SA_OK.
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successful
*                SAF_TEST_FAIL when an unexpected error occurs
******************************************************************************/
int main()
{
	SaHpiSessionIdT session_id;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiSessionOpen(SAHPI_UNSPECIFIED_DOMAIN_ID, &session_id, NULL);
	if (val != SA_OK) {
		e_print(saHpiSessionOpen, SA_OK, val);
		ret = SAF_TEST_FAIL;
	} else {
		ret = SAF_TEST_PASS;
		val = saHpiSessionClose(session_id);
	}

	return ret;
}

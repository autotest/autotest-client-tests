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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Wang Jing <jing.j.wang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiRdrGet
 * Description:   
 *   Call saHpiRdrGet passing NULL as RDR.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P75-28:P75-28
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resource_id = rpt_entry.ResourceId;
	SaHpiEntryIdT nextId;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	if ((rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_RDR)) {
		val = saHpiRdrGet(session_id, resource_id, SAHPI_FIRST_ENTRY,
				  &nextId, NULL);
		if (val != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(saHpiRdrGet, SA_ERR_HPI_INVALID_PARAMS, val);
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	} else
		ret = SAF_TEST_NOTSUPPORT;

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}

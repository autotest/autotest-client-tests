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
 * Authors:
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogInfoGet
 * Description:   
 *   Call saHpiEventLogInfoGet on every domain.
 *   saHpiEventLogInfoGet() never returns SA_ERR_HPI_CAPABILITY.
 * Line:        P48-24:P48-25
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventLogInfoT info;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiEventLogInfoGet(session_id,
				   SAHPI_UNSPECIFIED_RESOURCE_ID, &info);
	if (val == SA_ERR_HPI_CAPABILITY) {
		e_print(saHpiEventLogInfoGet, SA_OK, SA_ERR_HPI_CAPABILITY);
		ret = SAF_TEST_FAIL;
	} else
		ret = SAF_TEST_PASS;

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

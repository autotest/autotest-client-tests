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
 * Function:    saHpiEventLogTimeSet
 * Description: 
 *   Call saHpiEventLogTimeSet on every domain event log.
 *   Expected return:  call never returns SA_ERR_HPI_CAPABILITY.
 * Line:        P55-17:P55-18
 */

#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiTimeT RestoreTime;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiEventLogTimeGet(session_id,
				   SAHPI_UNSPECIFIED_RESOURCE_ID, &RestoreTime);
	if (val != SA_OK) {
		ret = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventLogTimeGet, SA_OK, val);
	} else {
		val = saHpiEventLogTimeSet(session_id,
					   SAHPI_UNSPECIFIED_RESOURCE_ID,
					   RestoreTime);
		if (val == SA_ERR_HPI_CAPABILITY) {
			ret = SAF_TEST_FAIL;
			e_print(saHpiEventLogTimeSet, !SA_ERR_HPI_CAPABILITY,
				val);
		} else {
			ret = SAF_TEST_PASS;
		}
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

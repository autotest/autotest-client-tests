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
 * Function:    saHpiResourceIdGet
 * Description:   
 *   Obtain the resource ID of the resource associated with
 *   the entity upon which the caller is running.
 *   Expected return: SA_OK.
 * Line:        P45-13:P45-13
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session)
{
	SaHpiResourceIdT resource_id;
	SaErrorT val;
	SaHpiRptEntryT rpt_entry;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiResourceIdGet(session, &resource_id);

	if (val == SA_OK) {
		// verify that the resource id is valid by retrieving its RPT entry.

		val =
		    saHpiRptEntryGetByResourceId(session, resource_id,
						 &rpt_entry);

		if (val == SA_OK) {
			ret = SAF_TEST_PASS;
		} else if (val == SA_ERR_HPI_INVALID_RESOURCE) {
			e_print(saHpiRptEntryGetByResourceId, SA_OK, val);
			ret = SAF_TEST_FAIL;
		} else {
			e_print(saHpiRptEntryGetByResourceId, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
		}
	} else if (val == SA_ERR_HPI_NOT_PRESENT || val == SA_ERR_HPI_UNKNOWN) {
		ret = SAF_TEST_NOTSUPPORT;
	} else {
		e_print(saHpiResourceIdGet, SA_OK
			|| SA_ERR_HPI_NOT_PRESENT, val);
		ret = SAF_TEST_FAIL;
	}

	return (ret);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_single_domain(Test_Resource);

	return (retval);
}

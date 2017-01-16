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
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogTimeSet
 * Description:   
 *   Call saHpiEventLogTimeSet while passing in a bad ResourceId.
 *   saHpiEventLogTimeSet() returns SA_ERR_HPI_INVALID_RESOURCE.
 * Line:        P29-44:P29-46
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	//  Call saHpiEventLogTimeSet passing in a bad ResourceId
	//
	status = saHpiEventLogTimeSet(session, INVALID_RESOURCE_ID, 0);

	if (status != SA_ERR_HPI_INVALID_RESOURCE
	    && status != SA_ERR_HPI_INVALID_DATA) {
		e_print(saHpiEventLogTimeSet,
			SA_ERR_HPI_INVALID_RESOURCE || SA_ERR_HPI_INVALID_DATA,
			status);
		retval = SAF_TEST_FAIL;
	} else
		retval = SAF_TEST_PASS;

	return (retval);
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

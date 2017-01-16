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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourceTagSet
 * Description:
 *   Call saHpiResourceTagSet while passing in an invalid Resource ID.
 *   Expected return: SA_ERR_HPI_INVALID_RESOURCE.
 * Line:        P29-44:P29-46
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STR        "Test Tag Components"

int Test_Resource(SaHpiSessionIdT session)
{
	SaErrorT status;
	SaHpiTextBufferT tag;
	int retval = SAF_TEST_UNKNOWN;

	memset(&tag, 0, sizeof(tag));
	tag.DataType = SAHPI_TL_TYPE_TEXT;
	tag.Language = SAHPI_LANG_ENGLISH;
	tag.DataLength = sizeof(TEST_STR);
	memcpy(tag.Data, TEST_STR, tag.DataLength);

	//
	//  Call saHpiResourceTagSet while passing in an invalid
	//    resource id
	//
	status = saHpiResourceTagSet(session, INVALID_RESOURCE_ID, &tag);

	if (status == SA_ERR_HPI_INVALID_RESOURCE) {
		retval = SAF_TEST_PASS;
	} else {
		e_print(saHpiResourceTagSet, SA_ERR_HPI_INVALID_RESOURCE,
			status);
		retval = SAF_TEST_FAIL;
	}
	return retval;
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

	return retval;
}

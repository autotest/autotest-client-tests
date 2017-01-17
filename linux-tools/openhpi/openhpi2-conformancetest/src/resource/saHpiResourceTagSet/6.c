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
 *   Call saHpiResourceTagSet setting the ResourceTag->DataType 
 *   to SAHPI_TL_TYPE_TEXT and the ResourceTag->Language to
 *   an out-of-range value.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P44-19:P44-20
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId, SaHpiTextTypeT dataType)
{
	int retval;
	SaErrorT status;
	SaHpiTextBufferT resource_tag;

	// set a test string
	resource_tag.DataType = dataType;
	resource_tag.Language = SAHPI_LANG_ZULU + 1;	//out-of-range
	resource_tag.DataLength = 2;
	resource_tag.Data[0] = 'a';
	resource_tag.Data[1] = 'a';

	status = saHpiResourceTagSet(sessionId, resourceId, &resource_tag);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiResourceTagSet, SA_ERR_HPI_INVALID_PARAMS, status);
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaErrorT status;
	int retval;
	SaHpiResourceIdT resourceId = rpt_entry.ResourceId;

	retval = run_test(sessionId, resourceId, SAHPI_TL_TYPE_TEXT);
	if (retval == SAF_TEST_PASS) {
		retval = run_test(sessionId, resourceId, SAHPI_TL_TYPE_UNICODE);
	}
	// Restore the original resource tag just in case
	status =
	    saHpiResourceTagSet(sessionId, resourceId, &rpt_entry.ResourceTag);
	if (status != SA_OK) {
		e_print(saHpiResourceTagSet, SA_OK, status);
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
	return process_all_domains(Test_Resource, NULL, NULL);
}

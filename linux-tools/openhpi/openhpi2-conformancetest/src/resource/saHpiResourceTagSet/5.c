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
 *   Call saHpiResourceTagSet setting an invalid character 
 *   in the ResourceTag->Data. 
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P44-18:P44-18
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define CARRIAGE_RETURN 0x0d

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiTextTypeT dataType, SaHpiUint8T data)
{
	SaErrorT status;
	int retval;
	SaHpiTextBufferT resource_tag;

	// set a test string
	resource_tag.DataType = dataType;
	resource_tag.Language = SAHPI_LANG_ENGLISH;
	resource_tag.DataLength = 1;
	resource_tag.Data[0] = data;

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

	retval =
	    run_test(sessionId, resourceId, SAHPI_TL_TYPE_ASCII6,
		     CARRIAGE_RETURN);
	if (retval == SAF_TEST_PASS) {
		retval =
		    run_test(sessionId, resourceId, SAHPI_TL_TYPE_BCDPLUS, 'a');
		if (retval == SAF_TEST_PASS) {
			retval =
			    run_test(sessionId, resourceId,
				     SAHPI_TL_TYPE_UNICODE, 'a');
		}
	}
	//  Restore the Resource Tag in case it was accidentally changed
	status = saHpiResourceTagSet(sessionId, resourceId,
				     &rpt_entry.ResourceTag);

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

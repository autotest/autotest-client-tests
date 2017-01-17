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
 *   to an out-of-range value.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P44-17:P44-17
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define HPI_TEST_STRING "test_string"
#define HPI_TEST_STRING_LENGTH 11
int Test_Resource(SaHpiSessionIdT session)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT RptNextEntry;
	SaHpiRptEntryT Report;
	SaHpiTextBufferT resource_tag;

	// set a test string
	resource_tag.DataType = SAHPI_TL_TYPE_BINARY + 1;	//out-of-range
	resource_tag.Language = SAHPI_LANG_ENGLISH;
	resource_tag.DataLength = HPI_TEST_STRING_LENGTH;
	strncpy(resource_tag.Data, HPI_TEST_STRING, HPI_TEST_STRING_LENGTH);

	//
	// Obtain a ResourceId
	//
	status = saHpiRptEntryGet(session,
				  SAHPI_FIRST_ENTRY, &RptNextEntry, &Report);

	if (status != SA_OK) {
		if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_NOTSUPPORT;
		} else {
			e_print(saHpiRptEntryGet, SA_OK
				|| SA_ERR_HPI_NOT_PRESENT, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	} else {

		//
		//   Call saHpiResourceTagSet setting the 
		//    ResourceTag->DataType to an out-of-range
		//    value.
		//
		status = saHpiResourceTagSet(session,
					     Report.ResourceId, &resource_tag);

		if (status == SA_ERR_HPI_INVALID_PARAMS)
			retval = SAF_TEST_PASS;
		else {
			e_print(saHpiResourceTagSet,
				SA_ERR_HPI_INVALID_PARAMS, status);
			retval = SAF_TEST_FAIL;

			// clean-up
			//  Restore the Resource Tag if corrupted.
			status = saHpiResourceTagSet(session,
						     Report.ResourceId,
						     &Report.ResourceTag);

			if (status != SA_OK) {
				e_print(saHpiResourceTagSet, SA_OK, status);
			}
		}
	}
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

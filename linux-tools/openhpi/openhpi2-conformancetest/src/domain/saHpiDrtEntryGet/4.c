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
 * Function:    saHpiDrtEntryGet
 * Description:   
 *   Pass in a NULL pointer for DrtEntry.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P37-24:P37-24
 */
#include <stdio.h>
#include "saf_test.h"

/**********************************************************
*
*   Pass in a NULL pointer for DrtEntry.
*
*   Expected return:  saHpiDrtEntryGet() returns 
*                      SA_ERR_HPI_INVALID_PARAMS.
*
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaHpiEntryIdT next_entry_id;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Retrieve the Domain Information with a bad entryId.
	//
	status = saHpiDrtEntryGet(sessionId,
				  SAHPI_FIRST_ENTRY, &next_entry_id, NULL);

	if (status == SA_ERR_HPI_INVALID_PARAMS)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiDrtEntryGet, SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
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

	retval = process_all_domains(NULL, NULL, Test_Domain);

	return (retval);
}

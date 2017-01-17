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
 * Function:    saHpiRptEntryGet
 * Description:   
 *   Pass in EntryId with the SAHPI_LAST_ENTRY value.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P40-26:P40-26
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiRptEntryT ReportEntry;
	SaHpiEntryIdT EntryId;

	//
	//  Call saHpiRptEntryGet passing in EntryId with the 
	//   SAHPI_LAST_ENTRY value.
	//

	status = saHpiRptEntryGet(session,
				  SAHPI_LAST_ENTRY, &EntryId, &ReportEntry);

	if (status == SA_ERR_HPI_INVALID_PARAMS)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiRptEntryGet, SA_ERR_HPI_INVALID_PARAMS, status);
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

	retval = process_all_domains(NULL, NULL, Test_Resource);

	return (retval);
}

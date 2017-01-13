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
 * Function:    saHpiEventLogEntryGet
 * Description:   
 *   Call saHpiEventLogEntryGet on all domain event logs.
 *   saHpiEventLogEntryGet() never returns SA_ERR_HPI_CAPABILITY.
 * Line:        P50-2:P50-3
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventLogEntryIdT PrevEntryId, NextEntryId;
	SaHpiEventLogEntryT EventLogEntry;

	status = saHpiEventLogEntryGet(session_id,
				       SAHPI_UNSPECIFIED_RESOURCE_ID,
				       SAHPI_OLDEST_ENTRY,
				       &PrevEntryId,
				       &NextEntryId,
				       &EventLogEntry, NULL, NULL);
	if (status != SA_ERR_HPI_CAPABILITY)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiEventLogEntryGet,
			status != SA_ERR_HPI_CAPABILITY, status);
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

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
 * Authors:
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogClear
 * Description: 
 *   Call saHpiEventLogClear on every domain.
 *   saHpiEventLogClear() never returns SA_ERR_HPI_CAPABILITY.
 * Line:        P53-14:P53-16
 *
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10
int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	if (retval == SAF_TEST_UNKNOWN) {
		status = saHpiEventLogClear(session, resource);
		if (status == SA_ERR_HPI_CAPABILITY) {
			e_print(saHpiEventLogClear, SA_OK,
				SA_ERR_HPI_CAPABILITY);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
	}

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	// On each domain, test the domain event log.
	retval = Test_Resource(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

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

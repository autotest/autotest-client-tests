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
 *   Get all of the rpt entries in all in each domain.
 *   Expected return: SA_OK.
 * Line:        P40-28:40-32
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEntryIdT next_entry_id, temp_id;
	SaHpiRptEntryT rpt_entry;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	// Loop through the rest of the domains, 
	// skipping over the one which we just tested
	next_entry_id = SAHPI_FIRST_ENTRY;

	while (next_entry_id != SAHPI_LAST_ENTRY) {
		temp_id = next_entry_id;

		status = saHpiRptEntryGet(session_id,
					  temp_id, &next_entry_id, &rpt_entry);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			if (temp_id != SAHPI_FIRST_ENTRY) {
				// Bad ID was returned last time.
				m_print
				    ("Unexpected error when executing \"saHpiRptEntryGet()\"");
				m_print
				    ("A returned entry_id does not retrieve an RptEntry");

				e_print(saHpiRptEntryGet, SA_OK
					|| SA_ERR_HPI_NOT_PRESENT, status);

				retval = SAF_TEST_FAIL;
			} else {
				// Empty Domain, No resources
				retval = SAF_TEST_NOTSUPPORT;
			}
			break;
		}
		// test if error
		if (status != SA_OK) {
			e_print(saHpiRptEntryGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
			break;
		}

		retval = SAF_TEST_PASS;

	}			//end of while loop testing each child domain

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

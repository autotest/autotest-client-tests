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
 * Function:    saHpiDrtEntryGet
 * Description:   
 *   Get all of the DRT entries in all in each domain.
 *   Expected return: SA_OK.
 * Line:        P37-19:P37-19
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEntryIdT next_entry_id, temp_id;
	SaHpiDrtEntryT domain_table_entry;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	// Loop through the rest of the domains, 
	// skipping over the one which we just tested
	next_entry_id = SAHPI_FIRST_ENTRY;
	while (next_entry_id != SAHPI_LAST_ENTRY) {
		temp_id = next_entry_id;
		status = saHpiDrtEntryGet(session_id,
					  temp_id,
					  &next_entry_id, &domain_table_entry);
		// test if empty
		if (status == SA_ERR_HPI_NOT_PRESENT) {
			if (next_entry_id != SAHPI_FIRST_ENTRY) {
				m_print
				    ("saHpiDrtEntryGet() returned NOT_PRESENT when next_entry_id!=SAHPI_FIRST_ENTRY.");
				retval = SAF_TEST_FAIL;
			} else
				retval = SAF_TEST_NOTSUPPORT;
			break;
		}
		// test if error
		if (status != SA_OK) {
			e_print(saHpiDrtEntryGet, SA_OK, status);
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

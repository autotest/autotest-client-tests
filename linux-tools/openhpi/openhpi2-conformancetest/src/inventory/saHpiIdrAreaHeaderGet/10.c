/*      -*- linux-c -*-
 *
 * (C) Copyright IBM Corp. 2004, 2005
 *
 *   This program is free software; you can redistribute it and/or modify 
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or 
 *   (at your option) any later version.
 *   This program is distributed in the hope that it will be useful, 
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *   GNU General Public License for more details. 
 *   You should have received a copy of the GNU General Public License 
 *   along with this program; if not, write to the Free Software 
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 
 *   USA 
 *
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAreaHeaderGet
 * Description:
 *      Call saHpiIdrAreaHeaderGet() with the NextAreaId pointer set to NULL.
 *      Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P102-37:P102-37
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/***********************************************************************
 *
 * Test NULL for the NextAreadId parameter.
 *
 ***********************************************************************/

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiIdrAreaHeaderT Header;

	if (hasInventoryCapability(&report)) {

		//
		// Call saHpiIdrAreaHeaderGet() with the NextAreaId pointer
		// set to NULL.
		//
		status = saHpiIdrAreaHeaderGet(sessionId,
					       report.ResourceId,
					       SAHPI_DEFAULT_INVENTORY_ID,
					       SAHPI_IDR_AREATYPE_UNSPECIFIED,
					       SAHPI_FIRST_ENTRY,
					       NULL, &Header);

		if (status == SA_ERR_HPI_INVALID_PARAMS) {
			retval = SAF_TEST_PASS;
		} else if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_PASS;	// Should this be NOTSUPPORT?
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaHeaderGet,
				SA_ERR_HPI_NOT_PRESENT
				|| SA_ERR_HPI_INVALID_PARAMS, status);
		}
	}

	return retval;
}

/***********************************************************************
 *
 * Main Program
 *
 ***********************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, NULL, NULL);
}

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
 * Function:    saHpiIdrInfoGet
 * Description:
 *   Pass in an invalid SessionID.
 *   Expected return: SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/********************************************************************
 *
 * Test an invalid session id.
 *      
 ********************************************************************/

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiIdrInfoT IdrInfo;

	if (hasInventoryCapability(&report)) {

		//
		// Call saHpiIdrInfoGet() passing in an invalid SessionId
		//
		status = saHpiIdrInfoGet(INVALID_SESSION_ID,
					 report.ResourceId,
					 SAHPI_DEFAULT_INVENTORY_ID, &IdrInfo);

		if (status == SA_ERR_HPI_INVALID_SESSION) {
			retval = SAF_TEST_PASS_AND_EXIT;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrInfoGet, SA_ERR_HPI_INVALID_SESSION,
				status);
		}
	}

	return retval;
}

/********************************************************************
 *
 * Main Program
 *      
 ********************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, NULL, NULL);
}

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
 *   Pass in an invalid ResourceID.
 *   Expected return: SA_ERR_HPI_INVALID_RESOURCE.
 * Line:        P29-44:P29-46
 *    
 */

#include <stdio.h>
#include "saf_test.h"

/******************************************************************
 *
 * Test an invalid resource id.
 *
 ******************************************************************/

int TestCase_Domain(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrInfoT IdrInfo;

	//
	// Call saHpiIdrInfoGet() passing in an invalid ResourceId
	//
	status = saHpiIdrInfoGet(sessionId,
				 INVALID_RESOURCE_ID,
				 SAHPI_DEFAULT_INVENTORY_ID, &IdrInfo);

	if (status == SA_ERR_HPI_INVALID_RESOURCE) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrInfoGet, SA_ERR_HPI_INVALID_RESOURCE, status);
	}

	return retval;
}

/******************************************************************
 *
 * Main Program
 *
 ******************************************************************/

int main(int argc, char **argv)
{
	return process_single_domain(TestCase_Domain);
}

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
 *   Retrieve information on the IDR.
 *   Expected return: SA_OK.
 * Line:        P101-17:P101-17
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Retrieve the Idr Info which should be successful.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrInfoT IdrInfo;

	status = saHpiIdrInfoGet(sessionId, resourceId,
				 inventoryRec->IdrId, &IdrInfo);

	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_PASS;	// Idr info is not present for this IDR (is this a bug?)
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrInfoGet,
			SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
	}

	return retval;
}

/*************************************************************************
 *
 *  Process all Inventory RDRs.  The below macro expands to
 *  generate all of the generic codes necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllInventoryRdrs(processInventoryRdr)

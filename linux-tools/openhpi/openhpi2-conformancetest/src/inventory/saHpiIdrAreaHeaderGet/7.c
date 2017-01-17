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
 *   AreaType is set to a specific area, but an area matching both the AreaId
 *   parameter and the AreaType does not exist in the IDR.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P102-32:P102-33
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Test an AreaType that does not exist in the IDR.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT NextAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiIdrAreaTypeT AreaType;
	SaHpiBoolT found;

	status =
	    getUnusedAreaType(sessionId, resourceId, inventoryRec->IdrId,
			      &AreaType, &found);
	if (status != SA_OK) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else if (!found) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		status = saHpiIdrAreaHeaderGet(sessionId, resourceId,
					       inventoryRec->IdrId,
					       AreaType, SAHPI_FIRST_ENTRY,
					       &NextAreaId, &Header);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaHeaderGet, SA_ERR_HPI_NOT_PRESENT,
				status);
		}
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

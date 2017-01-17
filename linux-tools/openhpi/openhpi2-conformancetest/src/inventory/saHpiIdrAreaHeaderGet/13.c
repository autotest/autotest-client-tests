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
 * Function:    saHpiIdrAreaHeaderGet
 * Description:
 *   Retrieve all Area Headers.
 *   Expected return: SA_OK or SA_ERR_HPI_NOT_PRESENT.
 * Line:        P103-4:P103-7
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Traverse the IDR retrieving all of the areas, if any.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEntryIdT NextAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiEntryIdT CurAreaId;

	NextAreaId = SAHPI_FIRST_ENTRY;
	while (NextAreaId != SAHPI_LAST_ENTRY) {

		CurAreaId = NextAreaId;
		status =
		    saHpiIdrAreaHeaderGet(sessionId, resourceId,
					  inventoryRec->IdrId,
					  SAHPI_IDR_AREATYPE_UNSPECIFIED,
					  CurAreaId, &NextAreaId, &Header);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing
		} else if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaHeaderGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
			break;
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

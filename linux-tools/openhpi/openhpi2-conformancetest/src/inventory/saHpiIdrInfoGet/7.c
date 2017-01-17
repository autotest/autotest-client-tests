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
 *   Get the counter, make a change in the IDR, check the counter again.
 *   The counter should have been incremented.
 *   Expected return: SA_OK.
 * Line:        P101-23:P101-28
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * When an Idr is changed, its UpdateCount gets incremented.  To test
 * this, an area is added.  
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrInfoT IdrInfoBefore;
	SaHpiEntryIdT AreaId;
	SaHpiIdrInfoT IdrInfoAfter;
	SaHpiIdrIdT IdrId = inventoryRec->IdrId;

	// Get the current value of the UpdateCount.

	status = saHpiIdrInfoGet(sessionId, resourceId, IdrId, &IdrInfoBefore);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (IdrInfoBefore.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		// Add an area which should cause the UpdateCount to increment.

		status = saHpiIdrAreaAdd(sessionId, resourceId, IdrId,
					 SAHPI_IDR_AREATYPE_PRODUCT_INFO,
					 &AreaId);

		if (status == SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaAdd, SA_OK, status);
		} else {

			// Check the UpdateCount.

			status =
			    saHpiIdrInfoGet(sessionId, resourceId, IdrId,
					    &IdrInfoAfter);

			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiIdrInfoGet, SA_OK, status);
			} else if (IdrInfoAfter.UpdateCount >
				   IdrInfoBefore.UpdateCount) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				m_print
				    ("Update Count not changed when the Inventory Data changes!");
			}

			// Remove the Area that we added.

			status =
			    saHpiIdrAreaDelete(sessionId, resourceId, IdrId,
					       AreaId);
			if (status != SA_OK) {
				e_print(saHpiIdrAreaDelete, SA_OK, status);
			}
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

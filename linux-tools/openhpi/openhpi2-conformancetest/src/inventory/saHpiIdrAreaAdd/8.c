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
 * Function:    saHpiIdrAreaAdd
 * Description:
 *   Call saHpiIdrAreaAdd() passing in a Area Type which is out-of-range.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P104-29:P104-29
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Test adding an area with an invalid area type.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT idrId, SaHpiIdrAreaTypeT invalidAreaType)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT AreaId;

	status = saHpiIdrAreaAdd(sessionId, resourceId, idrId,
				 invalidAreaType, &AreaId);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrAreaAdd, SA_ERR_HPI_INVALID_PARAMS, status);
	}

	return retval;
}

/*************************************************************************
 *
 * Test a variety of AreaTypes that are out of range.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval;
	int i;
	SaHpiIdrInfoT IdrInfo;
	SaHpiIdrAreaTypeT invalidAreaType[] =
	    { SAHPI_IDR_AREATYPE_PRODUCT_INFO + 1,
		SAHPI_IDR_AREATYPE_INTERNAL_USE - 1,
		SAHPI_IDR_AREATYPE_OEM - 1,
		SAHPI_IDR_AREATYPE_OEM + 1,
		SAHPI_IDR_AREATYPE_UNSPECIFIED - 1
	};

	// Check to see if this is a read-only IDR
	status = saHpiIdrInfoGet(sessionId, resourceId,
				 inventoryRec->IdrId, &IdrInfo);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (IdrInfo.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		retval = SAF_TEST_PASS;
		for (i = 0; i < 5 && retval == SAF_TEST_PASS; i++) {
			retval =
			    run_test(sessionId, resourceId, inventoryRec->IdrId,
				     invalidAreaType[i]);
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

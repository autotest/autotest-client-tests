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
 * Function:    saHpiIdrFieldSet
 * Description:
 *   Pass in an invalid ResourceID.
 *   Expected return: SA_ERR_HPI_INVALID_RESOURCE.
 * Line:        P29-44:P29-46
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Test an invalid resource id.  Since we need to use a valid Field,
 * we will use one of the fields belonging to the Area.  Since we are
 * using an invalid resource id, there should be no danger in setting
 * that field.
 *
 *************************************************************************/

int TestField(SaHpiSessionIdT sessionId,
	      SaHpiResourceIdT resourceId,
	      SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	int response;
	SaHpiIdrFieldT Field;

	response = getField(sessionId, resourceId, IdrId, AreaId, &Field);
	if (response == SAF_TEST_NOTSUPPORT) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (response == SAF_TEST_FAIL) {
		e_trace();
		retval = SAF_TEST_UNRESOLVED;
	} else {

		Field.ReadOnly = SAHPI_FALSE;
		status = saHpiIdrFieldSet(sessionId,
					  INVALID_RESOURCE_ID, IdrId, &Field);

		if (status == SA_ERR_HPI_INVALID_RESOURCE) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrFieldSet,
				SA_ERR_HPI_INVALID_RESOURCE, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Traverse the Areas in the IDR.  Don't care about the ReadOnly flags since
 * we will be using an invalid resource id.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiEntryIdT AreaId, NextAreaId;
	SaHpiIdrAreaHeaderT Header;

	NextAreaId = SAHPI_FIRST_ENTRY;
	while ((retval == SAF_TEST_NOTSUPPORT) &&
	       (NextAreaId != SAHPI_LAST_ENTRY)) {

		AreaId = NextAreaId;
		status = saHpiIdrAreaHeaderGet(sessionId,
					       resourceId,
					       inventoryRec->IdrId,
					       SAHPI_IDR_AREATYPE_UNSPECIFIED,
					       AreaId, &NextAreaId, &Header);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing
		} else if (status != SA_OK) {

			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaHeaderGet, SA_OK, status);

		} else {

			retval = TestField(sessionId, resourceId,
					   inventoryRec->IdrId, AreaId);
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

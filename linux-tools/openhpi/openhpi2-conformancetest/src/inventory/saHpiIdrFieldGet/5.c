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
 * Function:    saHpiIdrFieldGet
 * Description:
 *   Call on an Inventory Data Repositories which does not exist. Pass 
 *   in an invalid IdrId.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P107-30:P107-31
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Test an invalid Idr Id.
 *
 *************************************************************************/

int Test_Field(SaHpiSessionIdT sessionId,
	       SaHpiResourceIdT resourceId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT NextFieldId;
	SaHpiIdrFieldT Field;

	//   Call the routine while passing in an invalid IdrId.

	status = saHpiIdrFieldGet(sessionId,
				  resourceId,
				  INVALID_INVENTORY_ID,
				  AreaId,
				  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
				  SAHPI_FIRST_ENTRY, &NextFieldId, &Field);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrFieldGet, SA_ERR_HPI_NOT_PRESENT, status);
	}

	return retval;
}

/*************************************************************************
 *
 * To perform this test, we need to use a valid AreaId.
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

	status = saHpiIdrAreaHeaderGet(sessionId,
				       resourceId,
				       inventoryRec->IdrId,
				       SAHPI_IDR_AREATYPE_UNSPECIFIED,
				       SAHPI_FIRST_ENTRY, &NextAreaId, &Header);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_OK) {
		retval = Test_Field(sessionId, resourceId, Header.AreaId);
	} else {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrAreaHeaderGet, SA_OK
			|| SA_ERR_HPI_NOT_PRESENT, status);
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

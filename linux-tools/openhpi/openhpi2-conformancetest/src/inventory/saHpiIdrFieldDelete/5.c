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
 * Function:    saHpiIdrFieldDelete
 * Description:
 *   Pass in an Invalid IdrId.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P113-21:P113-22
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Since we need to use a valid FieldId, use one of the current fields
 * in the Area.  We don't need to worry about its deletion since we
 * are testing an invalid IDR id.  There should be no way for the
 * field to be deleted unless the HPI implementation is really messed up.
 *
 *************************************************************************/

int deleteField(SaHpiSessionIdT sessionId,
		SaHpiResourceIdT resourceId,
		SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrFieldT Field;
	SaHpiEntryIdT NextFieldId;

	status = saHpiIdrFieldGet(sessionId, resourceId, IdrId, AreaId,
				  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
				  SAHPI_FIRST_ENTRY, &NextFieldId, &Field);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrFieldGet, SA_OK, status);
	} else {

		status = saHpiIdrFieldDelete(sessionId,
					     resourceId,
					     INVALID_INVENTORY_ID,
					     AreaId, Field.FieldId);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrFieldDelete,
				SA_ERR_HPI_NOT_PRESENT, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Traverse the Areas in a IDR.  Note that we don't care about
 * the ReadOnly flags.  Since we are testing an invalid IDR id,
 * the ReadOnly flag is irrelevant.  We only care about obtaining valid
 * id values to use in order to call saHpiIdrFieldDelete().
 *
 * Note that the below loop will only execute until we find an Area
 * with at least one Field.
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

		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaHeaderGet, SA_OK, status);
		} else {
			retval = deleteField(sessionId,
					     resourceId,
					     inventoryRec->IdrId,
					     Header.AreaId);
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

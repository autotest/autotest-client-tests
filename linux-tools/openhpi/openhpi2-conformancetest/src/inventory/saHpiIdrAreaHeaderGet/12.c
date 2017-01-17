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
 *   Retrieve an Area Header by its ID and by its type.
 *   Expected return: SA_OK.
 * Line:        P103-2:P103-3
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Verify that we can read all of the areas for a particular area type.
 * We must find the area that was added at the end.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT idrId,
	     SaHpiIdrAreaTypeT areaType, SaHpiEntryIdT areaId)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEntryIdT NextAreaId;
	SaHpiEntryIdT CurAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiBoolT found = SAHPI_FALSE;

	NextAreaId = SAHPI_FIRST_ENTRY;
	while (NextAreaId != SAHPI_LAST_ENTRY) {

		CurAreaId = NextAreaId;
		status =
		    saHpiIdrAreaHeaderGet(sessionId, resourceId, idrId,
					  areaType, CurAreaId, &NextAreaId,
					  &Header);
		if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaHeaderGet, SA_OK, status);
			break;
		} else if (Header.AreaId == areaId) {
			found = SAHPI_TRUE;
			if (NextAreaId != SAHPI_LAST_ENTRY) {
				m_print("Added area was not found at the end.");
				break;
			}
		}
	}

	if (!found) {
		retval = SAF_TEST_FAIL;
		m_print("Did not find the area that was added!");
	}

	return retval;
}

/*************************************************************************
 *
 * If we can add an area, then add a PRODUCT area and then verify
 * that we can read only the PRODUCT areas and that we find the
 * one that we added.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT AreaId;
	SaHpiIdrInfoT IdrInfo;
	SaHpiIdrIdT IdrId = inventoryRec->IdrId;

	// Check to see if this is a read-only IDR

	status = saHpiIdrInfoGet(sessionId, resourceId, IdrId, &IdrInfo);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (IdrInfo.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		status = saHpiIdrAreaAdd(sessionId, resourceId, IdrId,
					 SAHPI_IDR_AREATYPE_PRODUCT_INFO,
					 &AreaId);

		if (status == SA_ERR_HPI_INVALID_DATA) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaAdd, SA_OK, status);
		} else {
			retval = run_test(sessionId, resourceId, IdrId,
					  SAHPI_IDR_AREATYPE_PRODUCT_INFO,
					  AreaId);

			status = saHpiIdrAreaDelete(sessionId, resourceId,
						    IdrId, AreaId);
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

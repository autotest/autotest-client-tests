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
 *   Retrieve all of the Area Headers of a specific Area type.
 *   Expected return: SA_OK or SA_ERR_HPI_NOT_PRESENT.
 * Line:        P103-8:P103-11
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Read all of the areas for a particular area type.  Not that we should
 * get an area with a different area type.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT idrId, SaHpiIdrAreaTypeT areaType, int *count)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEntryIdT NextAreaId, AreaId;
	SaHpiIdrAreaHeaderT Header;

	*count = 0;
	NextAreaId = SAHPI_FIRST_ENTRY;
	while (NextAreaId != SAHPI_LAST_ENTRY) {
		AreaId = NextAreaId;
		status = saHpiIdrAreaHeaderGet(sessionId, resourceId, idrId,
					       areaType, AreaId, &NextAreaId,
					       &Header);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			break;
		} else if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrAreaHeaderGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
			break;
		} else if (Header.Type != areaType) {
			retval = SAF_TEST_FAIL;
			m_print("Expected area type %d, but retrieved %d",
				areaType, Header.Type);
			break;
		} else {
			(*count)++;
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Try reading the areas for each of the area types.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	int i;
	int count;
	int retval = SAF_TEST_PASS;
	SaHpiBoolT found = SAHPI_FALSE;

	SaHpiIdrAreaTypeT areaType[] = { SAHPI_IDR_AREATYPE_CHASSIS_INFO,
		SAHPI_IDR_AREATYPE_BOARD_INFO,
		SAHPI_IDR_AREATYPE_PRODUCT_INFO,
		SAHPI_IDR_AREATYPE_OEM
	};

	for (i = 0; i < 4 && retval == SAF_TEST_PASS; i++) {
		retval =
		    run_test(sessionId, resourceId, inventoryRec->IdrId,
			     areaType[i], &count);
		if (count > 0) {
			found = SAHPI_TRUE;
		}
	}

	// If we didn't encounter any areas, then return NOTSUPPORT
	// since we really can't say the test passed.

	if (retval == SAF_TEST_PASS && !found) {
		retval = SAF_TEST_NOTSUPPORT;
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

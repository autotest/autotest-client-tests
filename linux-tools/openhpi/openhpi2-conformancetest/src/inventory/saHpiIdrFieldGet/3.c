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
 *   For each IDA, read the first field entry.
 *   Expected return: SA_OK.
 * Line:        P107-27:P107-27
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Read the first field from an area, if there is one.
 *
 *************************************************************************/

int ReadFirstField(SaHpiSessionIdT session,
		   SaHpiResourceIdT resourceId,
		   SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT NextFieldId;
	SaHpiIdrFieldT Field;

	status = saHpiIdrFieldGet(session,
				  resourceId,
				  IdrId,
				  AreaId,
				  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
				  SAHPI_FIRST_ENTRY, &NextFieldId, &Field);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrFieldGet,
			SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
	}

	return retval;
}

/*************************************************************************
 *
 * For each Area, try to read the first field if there is one.  If at
 * any point, an error occurs, we will exit with a failure.  In order to
 * pass, there must be at least one field for at least one Area; if not,
 * then return NOTSUPPORT.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	int response;
	SaHpiEntryIdT AreaId, NextAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiBoolT passing = SAHPI_FALSE;

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
			e_print(saHpiIdrAreaHeaderGet, SA_OK
				|| SA_ERR_HPI_NOT_PRESENT, status);
		} else {

			response = ReadFirstField(sessionId,
						  resourceId,
						  inventoryRec->IdrId,
						  Header.AreaId);

			if (response == SAF_TEST_PASS) {
				passing = SAHPI_TRUE;
			} else if (response == SAF_TEST_FAIL) {
				retval = SAF_TEST_FAIL;
			}
		}
	}

	if (retval == SAF_TEST_NOTSUPPORT && passing) {
		retval = SAF_TEST_PASS;
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

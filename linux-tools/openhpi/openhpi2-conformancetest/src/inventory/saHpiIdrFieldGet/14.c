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
 *   For each IDR, get all of the fields in all of the areas.
 *   Expected return: SA_OK.
 * Line:        P108-7:P108-10
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Read all of the fields for an Area.  We will only pass if there
 * is one or more fields and we don't encounter any errors.  If there
 * are no fields, simply return NOTSUPPORT since we can't say for sure
 * that the function is working correctly.
 *
 *************************************************************************/

int ReadAllFields(SaHpiSessionIdT sessionId,
		  SaHpiResourceIdT resourceId,
		  SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval = SAF_TEST_NOTSUPPORT;
	SaHpiEntryIdT FieldId, NextFieldId;
	SaHpiIdrFieldT Field;
	SaHpiBoolT passing = SAHPI_FALSE;

	NextFieldId = SAHPI_FIRST_ENTRY;

	while ((NextFieldId != SAHPI_LAST_ENTRY) &&
	       (retval == SAF_TEST_NOTSUPPORT)) {

		FieldId = NextFieldId;
		status = saHpiIdrFieldGet(sessionId,
					  resourceId,
					  IdrId,
					  AreaId,
					  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
					  FieldId, &NextFieldId, &Field);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing
		} else if (status == SA_OK) {
			passing = SAHPI_TRUE;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrFieldGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
		}
	}

	if (retval == SAF_TEST_NOTSUPPORT && passing) {
		retval = SAF_TEST_PASS;
	}

	return retval;
}

/*************************************************************************
 *
 * For every Area in the IDR, read the fields.  In order to PASS, 
 * we have to find at least one Area with one or more Fields.  If we
 * don't find any areas or any areas with fields, then return NOTSUPPORT.
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
			e_print(saHpiIdrAreaHeaderGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
		} else {

			response = ReadAllFields(sessionId, resourceId,
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

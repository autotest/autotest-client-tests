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
 *   Fieldtype is set to a specific field type, 
 *   but a field matching both the FieldId parameter 
 *   and the FieldType parameter does not exist.
 *   Expected return: SA_ERR_HPI_NOT_PRESENT.
 * Line:        P107-35:P107-36
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * This is the actual test.  We will use a FieldId for a field that
 * does exist, but we will use a different AreaType.
 *
 *************************************************************************/

int TestCase_Field(SaHpiSessionIdT sessionId,
		   SaHpiResourceIdT resourceId,
		   SaHpiIdrIdT IdrId,
		   SaHpiEntryIdT AreaId,
		   SaHpiEntryIdT FieldId, SaHpiIdrAreaTypeT AreaType)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT NextFieldId;
	SaHpiIdrFieldT Field;

	status = saHpiIdrFieldGet(sessionId,
				  resourceId,
				  IdrId,
				  AreaId,
				  AreaType, FieldId, &NextFieldId, &Field);

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
 * If the area has a field, then use that field's ID but a 
 * different AreaType.
 *
 *************************************************************************/

int Test_Field(SaHpiSessionIdT sessionId,
	       SaHpiResourceIdT resourceId,
	       SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT NextFieldId;
	SaHpiIdrFieldT Field;
	SaHpiIdrAreaTypeT areaType;

	status = saHpiIdrFieldGet(sessionId,
				  resourceId,
				  IdrId,
				  AreaId,
				  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
				  SAHPI_FIRST_ENTRY, &NextFieldId, &Field);

	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrFieldGet, SA_OK, status);
	} else {
		if (Field.Type == SAHPI_IDR_FIELDTYPE_CUSTOM) {
			areaType = SAHPI_IDR_FIELDTYPE_CHASSIS_TYPE;
		} else {
			areaType = SAHPI_IDR_FIELDTYPE_CUSTOM;
		}
		retval =
		    TestCase_Field(sessionId, resourceId, IdrId, AreaId,
				   Field.FieldId, areaType);
	}

	return retval;
}

/*************************************************************************
 *
 * Traverse the areas in the IDR until we find one that has a field, 
 * which will terminate the loop.
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
		} else if (status == SA_OK) {
			retval = Test_Field(sessionId, resourceId,
					    inventoryRec->IdrId, Header.AreaId);
		} else {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaHeaderGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
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

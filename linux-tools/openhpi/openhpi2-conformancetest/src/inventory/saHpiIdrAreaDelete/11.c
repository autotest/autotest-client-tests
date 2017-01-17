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
 * Function:    saHpiIdrAreaDelete
 * Description:
 *   Add an Area with a field to this IDR.  Delete the area.  The
 *   Field will also be deleted.
 *   Expected return: SA_OK.
 * Line:        P106-30:P106-30
 */

#include <stdio.h>
#include <string.h>
#include "../include/inventory_test.h"

#define TEST_STRING "Test String Data"
#define TEST_STRING_LENGTH 16

/*************************************************************************
 *
 * In order to verify that all of the fields are deleted for a deleted
 * area, we will use the following steps:
 *
 *    1) Add an area.
 *    2) Add a field to the new area.
 *    3) Delete the area.
 *    4) Try retrieving the field.  This should fail.
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
	SaHpiIdrFieldT Field;
	SaHpiEntryIdT fieldId, NextFieldId;

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
		} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
			retval = SAF_TEST_NOTSUPPORT;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaAdd, SA_OK, status);
		} else {

			Field.AreaId = AreaId;
			Field.FieldId = 0;
			Field.ReadOnly = SAHPI_FALSE;
			Field.Type = SAHPI_IDR_FIELDTYPE_ASSET_TAG;
			Field.Field.DataLength = TEST_STRING_LENGTH;
			strncpy(Field.Field.Data, TEST_STRING,
				TEST_STRING_LENGTH);
			Field.Field.DataType = SAHPI_TL_TYPE_TEXT;
			Field.Field.Language = SAHPI_LANG_ENGLISH;

			status = saHpiIdrFieldAdd(sessionId, resourceId,
						  IdrId, &Field);

			if (status == SA_ERR_HPI_INVALID_DATA) {
				retval = SAF_TEST_NOTSUPPORT;
				deleteArea(sessionId, resourceId, IdrId,
					   AreaId);
			} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
				retval = SAF_TEST_NOTSUPPORT;
				deleteArea(sessionId, resourceId, IdrId,
					   AreaId);
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiIdrFieldAdd, SA_OK, status);
				deleteArea(sessionId, resourceId, IdrId,
					   AreaId);
			} else {

				fieldId = Field.FieldId;

				status = saHpiIdrAreaDelete(sessionId,
							    resourceId,
							    IdrId, AreaId);

				if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiIdrAreaDelete, SA_OK,
						status);
				} else {

					status =
					    saHpiIdrFieldGet(sessionId,
							     resourceId, IdrId,
							     AreaId,
							     SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
							     fieldId,
							     &NextFieldId,
							     &Field);

					if (status != SA_OK) {
						// In this test, we don't care how it
						// failed as long as it did.
						retval = SAF_TEST_PASS;
					} else {
						retval = SAF_TEST_FAIL;
						e_print(saHpiIdrFieldGet,
							!SA_OK, status);
					}
				}
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

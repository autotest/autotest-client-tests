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
 *   Retrieve a field by field type and field ID.
 *   Expected return: SA_OK.
 * Line:        P108-5:P108-6
 *    
 */

#include <stdio.h>
#include <string.h>
#include "../include/inventory_test.h"

#define HPI_TEST_STRING "Test String"
#define HPI_TEST_STRING_LENGTH 11

/*************************************************************************
 *
 * Add a Field to an Area.
 *
 *************************************************************************/

int addField(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT idrId, SaHpiEntryIdT areaId, SaHpiIdrFieldT * Field)
{
	int retval;
	SaErrorT status;

	strncpy(Field->Field.Data, HPI_TEST_STRING, HPI_TEST_STRING_LENGTH);
	Field->Field.DataLength = HPI_TEST_STRING_LENGTH;
	Field->Field.DataType = SAHPI_TL_TYPE_TEXT;
	Field->FieldId = 0;
	Field->Field.Language = SAHPI_LANG_ENGLISH;
	Field->AreaId = areaId;
	Field->ReadOnly = SAHPI_FALSE;
	Field->Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

	status = saHpiIdrFieldAdd(sessionId, resourceId, idrId, Field);
	if (status == SA_ERR_HPI_INVALID_DATA) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_READ_ONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrFieldAdd, SA_OK, status);
	}

	return retval;
}

/*************************************************************************
 *
 * Run the main test.  After adding a Field, we should be able to 
 * read the field directly and we should also be able to find the
 * field by retrieving all fields of the same FieldType.
 *
 *************************************************************************/

int runTest(SaHpiSessionIdT sessionId,
	    SaHpiResourceIdT resourceId,
	    SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	int response;
	SaHpiEntryIdT FieldId, NextFieldId;
	SaHpiIdrFieldT Field, MyField;

	response = addField(sessionId, resourceId, IdrId, AreaId, &MyField);
	if (response != SAF_TEST_PASS) {
		retval = response;
	} else {

		status = saHpiIdrFieldGet(sessionId,
					  resourceId,
					  IdrId,
					  AreaId,
					  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
					  MyField.FieldId,
					  &NextFieldId, &Field);

		if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrFieldGet, SA_OK, status);
		} else {

			retval = SAF_TEST_UNKNOWN;

			// Retrieve the field by Field type.

			NextFieldId = SAHPI_FIRST_ENTRY;
			while ((NextFieldId != SAHPI_LAST_ENTRY) &&
			       (retval == SAF_TEST_UNKNOWN)) {

				FieldId = NextFieldId;
				status = saHpiIdrFieldGet(sessionId,
							  resourceId,
							  IdrId,
							  AreaId,
							  SAHPI_IDR_FIELDTYPE_CUSTOM,
							  FieldId,
							  &NextFieldId, &Field);

				if (status == SA_ERR_HPI_NOT_PRESENT) {
					// do nothing
				} else if (status != SA_OK) {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiIdrFieldGet,
						SA_ERR_HPI_NOT_PRESENT, status);
				} else if (Field.FieldId == MyField.FieldId) {
					retval = SAF_TEST_PASS;
				}
			}

			if (retval == SAF_TEST_UNKNOWN) {
				retval = SAF_TEST_FAIL;
				m_print
				    ("\"saHpiIdrFieldGet()\" did not return newly added field!");
			}

			status = saHpiIdrFieldDelete(sessionId, resourceId,
						     IdrId, AreaId,
						     Field.FieldId);
			if (status != SA_OK) {
				e_print(saHpiIdrFieldDelete, SA_OK, status);
			}
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Add an Area.
 *
 *************************************************************************/

int addArea(SaHpiSessionIdT sessionId,
	    SaHpiResourceIdT resourceId,
	    SaHpiIdrIdT idrId, SaHpiEntryIdT * areaId)
{
	int retval;
	SaErrorT status;

	status = saHpiIdrAreaAdd(sessionId,
				 resourceId,
				 idrId,
				 SAHPI_IDR_AREATYPE_PRODUCT_INFO, areaId);

	if (status == SA_ERR_HPI_INVALID_DATA) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_READ_ONLY) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrAreaAdd, SA_OK, status);
	}

	return retval;
}

/*************************************************************************
 *
 * If we can find an Area to add a field to, use it.  Otherwise, try
 * adding a new Area.  In either case, run the test against the Area.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval;
	int response;
	SaHpiEntryIdT AreaId, NextAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiIdrIdT idrId = inventoryRec->IdrId;

	status = saHpiIdrAreaHeaderGet(sessionId,
				       resourceId,
				       idrId,
				       SAHPI_IDR_AREATYPE_UNSPECIFIED,
				       SAHPI_FIRST_ENTRY, &NextAreaId, &Header);

	if (status == SA_OK) {

		retval = runTest(sessionId, resourceId, idrId, Header.AreaId);

	} else if (status == SA_ERR_HPI_NOT_PRESENT) {

		response = addArea(sessionId, resourceId, idrId, &AreaId);
		if (response != SAF_TEST_PASS) {
			retval = response;
		} else {
			retval = runTest(sessionId, resourceId, idrId, AreaId);
			deleteArea(sessionId, resourceId, idrId, AreaId);
		}

	} else {

		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrAreaHeaderGet, SA_OK, status);
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

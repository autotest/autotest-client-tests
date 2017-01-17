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
 *   Create a field, and then delete it. Do this on all IDR 
 *   areas available.
 *   Expected return: SA_OK.
 * Line:        P113-18:P113-18
 *    
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Add a new Field that we can later delete.
 *
 *************************************************************************/

int addField(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId, SaHpiIdrFieldT * Field)
{
	SaErrorT status;
	int retval;

	Field->Field.Data[0] = 'a';
	Field->Field.DataLength = 1;
	Field->Field.DataType = SAHPI_TL_TYPE_TEXT;
	Field->FieldId = 0;
	Field->Field.Language = SAHPI_LANG_ENGLISH;
	Field->AreaId = AreaId;
	Field->ReadOnly = SAHPI_FALSE;
	Field->Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

	status = saHpiIdrFieldAdd(sessionId, resourceId, IdrId, Field);

	if (status == SA_ERR_HPI_INVALID_DATA) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_OUT_OF_MEMORY) {
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
 * Test deleting a Field by firstly adding a new Field and then
 * deleting it.
 *
 *************************************************************************/

int deleteField(SaHpiSessionIdT sessionId,
		SaHpiResourceIdT resourceId,
		SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	int response;
	SaHpiIdrFieldT Field;

	response = addField(sessionId, resourceId, IdrId, AreaId, &Field);

	if (response != SAF_TEST_PASS) {
		retval = response;
	} else {

		status = saHpiIdrFieldDelete(sessionId,
					     resourceId,
					     IdrId, AreaId, Field.FieldId);

		if (status == SA_OK) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			e_print(saHpiIdrFieldDelete, SA_OK, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Traverse all of the Areas.  For those that are not ReadOnly, 
 * test the deletion of a Field.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT AreaId, NextAreaId;
	SaHpiIdrAreaHeaderT Header;
	SaHpiIdrInfoT Info;
	int response;
	SaHpiBoolT passed = SAHPI_FALSE;

	status = saHpiIdrInfoGet(sessionId, resourceId,
				 inventoryRec->IdrId, &Info);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (Info.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		retval = SAF_TEST_NOTSUPPORT;

		NextAreaId = SAHPI_FIRST_ENTRY;
		while ((retval == SAF_TEST_NOTSUPPORT) &&
		       (NextAreaId != SAHPI_LAST_ENTRY)) {
			AreaId = NextAreaId;
			status = saHpiIdrAreaHeaderGet(sessionId,
						       resourceId,
						       inventoryRec->IdrId,
						       SAHPI_IDR_AREATYPE_UNSPECIFIED,
						       AreaId,
						       &NextAreaId, &Header);

			if (status == SA_ERR_HPI_NOT_PRESENT) {
				// do nothing
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiIdrAreaHeaderGet,
					SA_ERR_HPI_NOT_PRESENT, status);
			} else if (!Header.ReadOnly) {

				response = deleteField(sessionId,
						       resourceId,
						       inventoryRec->IdrId,
						       AreaId);

				if (response == SAF_TEST_PASS) {
					passed = SAHPI_TRUE;
				} else {
					retval = response;
				}
			}
		}

		if (retval == SAF_TEST_NOTSUPPORT && passed) {
			retval = SAF_TEST_PASS;
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

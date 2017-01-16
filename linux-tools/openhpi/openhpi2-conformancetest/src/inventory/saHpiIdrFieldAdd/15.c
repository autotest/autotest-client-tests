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
 * Function:    saHpiIdrFieldAdd
 * Description:
 *   Add a new field to an area in each IDR.  Verify that
 *   the FieldId is successfully set to a new value.
 *   Expected return: SA_OK.
 * Line:        P110-5:P110-6
 *    
 */

#include <stdio.h>
#include <string.h>
#include "../include/inventory_test.h"

#define HPI_TEST_STRING "Test String"
#define HPI_TEST_STRING_LENGTH 11

/*************************************************************************
 *
 * Add a field to an area.  Verify that the FieldId is successfully set.
 *
 * Note that it is possible for legal error codes to be returned.  
 * If that occurs, we will return NOTSUPPORT.
 *
 *************************************************************************/

int addField(SaHpiSessionIdT sessionId,
	     SaHpiResourceIdT resourceId,
	     SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval;
	SaHpiIdrFieldT Field;

	strncpy(Field.Field.Data, HPI_TEST_STRING, HPI_TEST_STRING_LENGTH);
	Field.Field.DataLength = HPI_TEST_STRING_LENGTH;
	Field.Field.DataType = SAHPI_TL_TYPE_TEXT;
	Field.FieldId = SAHPI_LAST_ENTRY;
	Field.Field.Language = SAHPI_LANG_ENGLISH;
	Field.AreaId = AreaId;
	Field.ReadOnly = SAHPI_FALSE;
	Field.Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

	status = saHpiIdrFieldAdd(sessionId, resourceId, IdrId, &Field);

	if (status == SA_ERR_HPI_INVALID_DATA) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status == SA_ERR_HPI_OUT_OF_SPACE) {
		retval = SAF_TEST_NOTSUPPORT;
	} else if (status != SA_OK) {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrFieldAdd, SA_OK, status);
	} else {
		if (Field.FieldId != SAHPI_LAST_ENTRY) {
			retval = SAF_TEST_PASS;
		} else {
			retval = SAF_TEST_FAIL;
			m_print
			    ("FieldId was not successfully updated by \"saHpiIdrFieldAdd()\".");
		}

		status =
		    saHpiIdrFieldDelete(sessionId, resourceId, IdrId, AreaId,
					Field.FieldId);
		if (status != SA_OK) {
			e_print(saHpiIdrFieldDelete, SA_OK, status);
		}
	}

	return retval;
}

/*************************************************************************
 *
 * For Areas that we can write to, try adding a Field.  If we can't find 
 * any Areas that we can write to, we will return NOTSUPPORT.
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
	SaHpiIdrInfoT Info;
	SaHpiIdrAreaHeaderT Header;
	SaHpiBoolT passed = SAHPI_FALSE;

	status = saHpiIdrInfoGet(sessionId, resourceId,
				 inventoryRec->IdrId, &Info);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (Info.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;	//IDR is read-only
	} else {

		retval = SAF_TEST_UNKNOWN;

		// Walk through all of the Areas 

		NextAreaId = SAHPI_FIRST_ENTRY;
		while ((retval == SAF_TEST_UNKNOWN) &&
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
					SA_OK
					|| SA_ERR_HPI_NOT_PRESENT, status);
			} else if (!Header.ReadOnly) {

				response = addField(sessionId,
						    resourceId,
						    inventoryRec->IdrId,
						    AreaId);

				if (response == SAF_TEST_PASS) {
					passed = SAHPI_TRUE;
				} else if (response == SAF_TEST_FAIL) {
					retval = SAF_TEST_FAIL;
				}
			}
		}

		// If we didn't encounter an failure and we
		// passed at least once, then return PASS; otherwise NOTSUPPORT 
		// since the saHpiIdrFieldAdd() didn't work as expected.

		if (retval == SAF_TEST_UNKNOWN) {
			if (passed) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_NOTSUPPORT;
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

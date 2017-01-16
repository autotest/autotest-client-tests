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
 *   Delete an IDA which contains a read-only field.
 *   Expected return: SA_ERR_HPI_READ_ONLY.
 * Line:        P106-27:P106-27
 */

#include <stdio.h>
#include "../include/inventory_test.h"

/*************************************************************************
 *
 * Determine if the given Area has a read-only field.  The "retval"
 * is being using in a funky way as described:
 *
 *     SAF_TEST_PASS: found a read-only field
 *     SAF_TEST_NOTSUPPORT: did not find a read-only field
 *     SAF_TEST_UNRESOLVED: something went wrong
 *
 *************************************************************************/

int hasReadOnlyField(SaHpiSessionIdT sessionId,
		     SaHpiResourceIdT resourceId,
		     SaHpiIdrIdT idrId, SaHpiEntryIdT areaId)
{
	int retval = SAF_TEST_NOTSUPPORT;
	SaErrorT status;
	SaHpiEntryIdT NextFieldId, FieldId;
	SaHpiIdrFieldT Field;

	NextFieldId = SAHPI_FIRST_ENTRY;
	while (NextFieldId != SAHPI_LAST_ENTRY && retval == SAF_TEST_NOTSUPPORT) {

		FieldId = NextFieldId;
		status = saHpiIdrFieldGet(sessionId,
					  resourceId,
					  idrId,
					  areaId,
					  SAHPI_IDR_FIELDTYPE_UNSPECIFIED,
					  FieldId, &NextFieldId, &Field);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrFieldGet, SA_OK, status);
			break;
		} else if (Field.ReadOnly) {
			retval = SAF_TEST_PASS;
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Find an Area with a read-only field.  Note that the Area itself 
 * cannot be read-only.   The "retval" is being using in a funky way as 
 * described:
 *
 *     SAF_TEST_PASS: found an area with a read-only field
 *     SAF_TEST_NOTSUPPORT: did not find an area with a read-only field
 *     SAF_TEST_UNRESOLVED: something went wrong
 *
 *************************************************************************/

int findAreaWithReadOnlyField(SaHpiSessionIdT sessionId,
			      SaHpiResourceIdT resourceId,
			      SaHpiIdrIdT idrId, SaHpiEntryIdT * areaId)
{
	int retval = SAF_TEST_NOTSUPPORT;
	SaErrorT status;
	SaHpiIdrAreaHeaderT Header;
	SaHpiEntryIdT AreaId, NextAreaId;

	NextAreaId = SAHPI_FIRST_ENTRY;
	while (NextAreaId != SAHPI_LAST_ENTRY && retval == SAF_TEST_NOTSUPPORT) {
		AreaId = NextAreaId;
		status = saHpiIdrAreaHeaderGet(sessionId,
					       resourceId,
					       idrId,
					       SAHPI_IDR_AREATYPE_UNSPECIFIED,
					       AreaId, &NextAreaId, &Header);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiIdrAreaHeaderGet, SA_ERR_HPI_NOT_PRESENT,
				status);
		} else if (!Header.ReadOnly) {
			retval =
			    hasReadOnlyField(sessionId, resourceId, idrId,
					     Header.AreaId);
			if (retval == SAF_TEST_PASS) {
				*areaId = Header.AreaId;
			}
		}
	}

	return retval;
}

/*************************************************************************
 *
 * Try deleting an Area that has a read-only field.  Note that the IDR
 * and the IDA cannot be read-only, only one of the fields.
 *
 *************************************************************************/

int processInventoryRdr(SaHpiSessionIdT sessionId,
			SaHpiResourceIdT resourceId,
			SaHpiRdrT * rdr, SaHpiInventoryRecT * inventoryRec)
{
	SaErrorT status;
	int retval;
	SaHpiEntryIdT AreaId;
	SaHpiIdrInfoT IdrInfo;

	// Check to see if this is a read-only IDR
	status = saHpiIdrInfoGet(sessionId, resourceId,
				 inventoryRec->IdrId, &IdrInfo);

	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiIdrInfoGet, SA_OK, status);
	} else if (IdrInfo.ReadOnly) {
		retval = SAF_TEST_NOTSUPPORT;
	} else {

		retval = findAreaWithReadOnlyField(sessionId,
						   resourceId,
						   inventoryRec->IdrId,
						   &AreaId);

		if (retval == SAF_TEST_PASS) {
			status = saHpiIdrAreaDelete(sessionId,
						    resourceId,
						    inventoryRec->IdrId,
						    AreaId);

			if (status == SA_ERR_HPI_READ_ONLY) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiIdrAreaDelete,
					SA_ERR_HPI_READ_ONLY, status);
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

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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiIdrFieldAdd
 * Description:
 *   Add a new field to an area in each IDR. Setting the 
 *   Read-only field to TRUE.
 *   saHpiIdrFieldAdd() returns SA_OK, the readonly field is 
 *   ignored and the Read-Only field is always set to FALSE.
 * Line:        P110-9:P110-10
 *    
 */

#include <stdio.h>
#include "saf_test.h"
#include <string.h>

/*************************************************************************************
 *
 * I think this test should be deleted, pending agreement from the WG review team.
 * It does the same thing as test 16.
 *
 *************************************************************************************/

#define HPI_TEST_STRING "Test String"
#define HPI_TEST_STRING_LENGTH 11

int Test_Fields(SaHpiSessionIdT session,
		SaHpiResourceIdT resourceId,
		SaHpiIdrIdT IdrId, SaHpiEntryIdT AreaId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrFieldT Field;

	strncpy(Field.Field.Data, HPI_TEST_STRING, HPI_TEST_STRING_LENGTH);
	Field.Field.DataLength = HPI_TEST_STRING_LENGTH;
	Field.Field.DataType = SAHPI_TL_TYPE_TEXT;
	Field.FieldId = 0;
	Field.Field.Language = SAHPI_LANG_ENGLISH;
	Field.AreaId = AreaId;
	Field.ReadOnly = SAHPI_TRUE;
	Field.Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

	status = saHpiIdrFieldAdd(session, resourceId, IdrId, &Field);
	if (status != SA_OK) {
		if (status != SA_ERR_HPI_OUT_OF_SPACE) {
			e_print(saHpiIdrFieldAdd,
				SA_OK || SA_ERR_HPI_OUT_OF_SPACE, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_NOTSUPPORT;
	} else {
		if (Field.ReadOnly == SAHPI_TRUE) {
			e_print(saHpiIdrFieldAdd,
				SA_OK && Field.ReadOnly != SAHPI_TRUE, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;

		// Clean up
		status = saHpiIdrFieldDelete(session,
					     resourceId,
					     IdrId, AreaId, Field.FieldId);
	}

	return (retval);
}

int Test_Rdr(SaHpiSessionIdT session,
	     SaHpiResourceIdT resourceId, SaHpiRdrT rdr)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	int status2 = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT AreaId, NextAreaId;
	SaHpiIdrInfoT Info;
	SaHpiIdrAreaHeaderT Header;
	SaHpiBoolT Passing = SAHPI_FALSE;

	if (rdr.RdrType == SAHPI_INVENTORY_RDR) {
		status = saHpiIdrInfoGet(session,
					 resourceId,
					 rdr.RdrTypeUnion.InventoryRec.IdrId,
					 &Info);
		if (status != SA_OK) {
			e_print(saHpiIdrInfoGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else if (Info.ReadOnly == SAHPI_TRUE)
			retval = SAF_TEST_NOTSUPPORT;	//IDR is read-only
	} else
		retval = SAF_TEST_NOTSUPPORT;	// Non Inventory Data Record

	if (retval == SAF_TEST_UNKNOWN) {
		// Walk through all of the Areas 
		NextAreaId = SAHPI_FIRST_ENTRY;
		while ((retval == SAF_TEST_UNKNOWN) &&
		       (NextAreaId != SAHPI_LAST_ENTRY)) {
			AreaId = NextAreaId;
			status = saHpiIdrAreaHeaderGet(session,
						       resourceId,
						       rdr.RdrTypeUnion.
						       InventoryRec.IdrId,
						       SAHPI_IDR_AREATYPE_UNSPECIFIED,
						       AreaId, &NextAreaId,
						       &Header);
			if (status != SA_OK) {
				//Problems occurred in getting area information
				if (status == SA_ERR_HPI_NOT_PRESENT)
					retval = SAF_TEST_NOTSUPPORT;
				else {
					e_print(saHpiIdrAreaHeaderGet,
						SA_OK || SA_ERR_HPI_NOT_PRESENT,
						status);
					retval = SAF_TEST_UNRESOLVED;
				}
			} else {
				if (Header.ReadOnly == SAHPI_TRUE)
					continue;	// Area is Read-only go on to the next

				status2 = Test_Fields(session,
						      resourceId,
						      rdr.RdrTypeUnion.
						      InventoryRec.IdrId,
						      Header.AreaId);
				if (status2 == SAF_TEST_PASS)
					Passing = SAHPI_TRUE;
				else if (status2 == SAF_TEST_FAIL) {
					retval = SAF_TEST_FAIL;
					break;
				}
			}
		}

		if (retval == SAF_TEST_UNKNOWN) {
			if (Passing == SAHPI_TRUE)
				retval = SAF_TEST_PASS;
			else
				retval = SAF_TEST_NOTSUPPORT;
		}
	}
	return (retval);
}

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_INVENTORY_DATA)
		retval = do_resource(session, report, func);
	else			//Resource Does not support IDR's
		retval = SAF_TEST_NOTSUPPORT;

	return (retval);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(Test_Resource, Test_Rdr, NULL);

	return (retval);
}

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
 *   Call on a resource which does not support Inventory Data Repositories.
 *   Expected return: SA_ERR_HPI_CAPABILITY.
 * Line:        P109-18:P109-19
 *    
 */

#include <stdio.h>
#include <string.h>
#include "../include/inventory_test.h"

#define HPI_TEST_STRING "Test String"
#define HPI_TEST_STRING_LENGTH 11

/*****************************************************************************
 *
 * Add a field to a resource that does not support inventories.
 *
 *****************************************************************************/

int addField(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiIdrFieldT Field;

	strncpy(Field.Field.Data, HPI_TEST_STRING, HPI_TEST_STRING_LENGTH);
	Field.Field.DataLength = HPI_TEST_STRING_LENGTH;
	Field.Field.DataType = SAHPI_TL_TYPE_TEXT;
	Field.FieldId = 0;
	Field.Field.Language = SAHPI_LANG_ENGLISH;
	Field.AreaId = 0;
	Field.ReadOnly = SAHPI_FALSE;
	Field.Type = SAHPI_IDR_FIELDTYPE_CUSTOM;

	status =
	    saHpiIdrFieldAdd(sessionId, resourceId, SAHPI_DEFAULT_INVENTORY_ID,
			     &Field);

	if (status == SA_ERR_HPI_CAPABILITY) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiIdrFieldAdd, SA_ERR_HPI_CAPABILITY, status);
	}

	return retval;
}

/*****************************************************************************
 *
 * Try adding a field to a resource that does not support inventories.
 *
 *****************************************************************************/

int Test_Resource(SaHpiSessionIdT sessionId,
		  SaHpiRptEntryT report, callback2_t func)
{
	int retval = SAF_TEST_NOTSUPPORT;

	if (!hasInventoryCapability(&report)) {
		retval = addField(sessionId, report.ResourceId);
	}

	return retval;
}

/*****************************************************************************
 *
 * Main Program
 *
 *****************************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(Test_Resource, NULL, NULL);
}

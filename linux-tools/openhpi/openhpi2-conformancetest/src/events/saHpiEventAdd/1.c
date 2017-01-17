/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 *
 * Author(s):
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Xiaowei Yang <xiaowei.yang@intel.com>
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventAdd
 * Description:   
 *   Call saHpiEventAdd() with an event which has a specific,
 *   invalid resourceId for a source.
 *   Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P64-19:64-19
 */
#include <stdio.h>
#include "saf_test.h"
#include <string.h>

#define TEST_STRING        "Test String"
#define TEST_STRING_LENGTH 11

int run_test(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	//
	// Create the event information
	//
	EvtEntry.EventType = SAHPI_ET_USER;
	EvtEntry.Severity = SAHPI_INFORMATIONAL;
	EvtEntry.Source = resource_id;
	EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_STRING, TEST_STRING_LENGTH);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_STRING_LENGTH;
	//
	//   Call saHpiEventAdd() with an event which has a specific,
	//   invalid resourceId for a source.
	//
	status = saHpiEventAdd(session_id, &EvtEntry);
	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiEventAdd, SA_ERR_HPI_INVALID_PARAMS, status);
	}

	return retval;
}

int Test_Resource(SaHpiSessionIdT session_id)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEntryIdT nextEntryId;
	SaHpiRptEntryT rptEntry;

	status =
	    saHpiRptEntryGet(session_id, SAHPI_FIRST_ENTRY, &nextEntryId,
			     &rptEntry);
	if (status == SA_ERR_HPI_NOT_PRESENT) {
		retval =
		    run_test(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID + 10);
	} else if (status == SA_OK) {
		retval = run_test(session_id, rptEntry.ResourceId);
	} else {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiRptEntryGet, SA_OK, status);
	}

	return retval;
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

	retval = process_single_domain(Test_Resource);

	return (retval);
}

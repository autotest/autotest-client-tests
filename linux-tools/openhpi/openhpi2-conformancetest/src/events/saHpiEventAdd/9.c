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
 *   Call saHpiEventAdd() with an event with an invalid 
 *   characters in the text buffer.
 *   Expected return:  call returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P64-25:P64-25
 */
#include <stdio.h>
#include <string.h>
#include <wchar.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session_id, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	//
	// Create the event information
	//
	EvtEntry.EventType = SAHPI_ET_USER;
	EvtEntry.Severity = SAHPI_INFORMATIONAL;
	EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
	EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength = 1;

	//Invalid Character
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_ASCII6;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 0x0D;

	//
	//   Call saHpiEventAdd() with an event with an invalid 
	//   characters in the text buffer.
	//
	status = saHpiEventAdd(session_id, &EvtEntry);
	if (status == SA_ERR_HPI_INVALID_PARAMS)
		goto test_bcdplus;
	else {
		e_print(saHpiEventLogEntryAdd,
			SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}

      test_bcdplus:
	/* BCDPLUS
	 * String of ASCII characters, '0'-'9', space,
	 * dash, period, colon, comma or underscore ONLY */
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_BCDPLUS;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 'a';

	status = saHpiEventLogEntryAdd(session_id, resource, &EvtEntry);

	if (status == SA_ERR_HPI_INVALID_PARAMS)
		goto test_text;
	else {
		e_print(saHpiEventLogEntryAdd,
			SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}

      test_text:
	/* Text shall be OK with any data */
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 'a';

	status = saHpiEventLogEntryAdd(session_id, resource, &EvtEntry);

	if (status == SA_OK)
		goto test_unicode;
	else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		goto out;
	}

      test_unicode:
	/* Unicode
	 * U+D800 ... U+DFFF are reserved for surrogate code.
	 */
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_UNICODE;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 'a';

	status = saHpiEventLogEntryAdd(session_id, resource, &EvtEntry);

	if (status == SA_ERR_HPI_INVALID_PARAMS)
		goto test_binary;
	else {
		e_print(saHpiEventLogEntryAdd,
			SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}

      test_binary:
	/* Binary shall be OK with any data */
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_BINARY;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 'a';

	status = saHpiEventLogEntryAdd(session_id, resource, &EvtEntry);

	if (status == SA_OK)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}

	//user events should clear the log before exiting
	status = saHpiEventLogClear(session_id, resource);
	if (status != SA_OK)
		e_print(saHpiEventLogClear, SA_OK, status);

      out:

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = Test_Resource(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

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

	retval = process_all_domains(NULL, NULL, Test_Domain);

	return (retval);
}

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
 *   Call saHpiEventAdd() with an event which is not of the 
 *   type SA_HPI_ET_USER.
 *   Expected return:  call returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P64-19:P64-20
 */
#include <stdio.h>
#include "saf_test.h"
#include <string.h>

#define TEST_STRING        "Test String"
#define TEST_STRING_LENGTH 11

int run_test(SaHpiSessionIdT session_id, SaHpiEventTypeT eventType)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	//
	// Create the event information
	//
	EvtEntry.EventType = eventType;
	EvtEntry.Severity = SAHPI_INFORMATIONAL;
	EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
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
	//   Call saHpiEventAdd() with an event of the type "SA_HPI_ET_OEM".
	//
	status = saHpiEventAdd(session_id, &EvtEntry);
	if (status == SA_ERR_HPI_INVALID_PARAMS)
		retval = SAF_TEST_PASS;
	else {
		e_print(saHpiEventAdd, SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;
	}
	return (retval);
}

int Test_Resource(SaHpiSessionIdT session_id)
{
	int i;
	int retval = SAF_TEST_UNKNOWN;

	SaHpiEventTypeT et[] = { SAHPI_ET_RESOURCE, SAHPI_ET_DOMAIN,
		SAHPI_ET_SENSOR, SAHPI_ET_SENSOR_ENABLE_CHANGE,
		SAHPI_ET_HOTSWAP, SAHPI_ET_WATCHDOG,
		SAHPI_ET_HPI_SW, SAHPI_ET_OEM
	};

	for (i = 0; i < 8; i++) {
		retval = run_test(session_id, et[i]);
		if (retval == SAF_TEST_FAIL) {
			break;
		}
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

	retval = process_all_domains(NULL, NULL, Test_Resource);

	return (retval);
}

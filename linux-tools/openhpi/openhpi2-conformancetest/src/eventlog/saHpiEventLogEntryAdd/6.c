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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryAdd
 * Description:   
 *   Call saHpiEventLogEntryAdd while passing in a DataLength which 
 *   is larger than that supported by the implementation and reported 
 *   in the Event Log info record. 
 *   saHpiEventLogEntryAdd() returns SA_ERR_HPI_INVALID_DATA.
 * Line:        P51-20:P51-21
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

// definitions
#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	SaHpiEventLogInfoT info;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	status = saHpiEventLogInfoGet(session, resource, &info);
	if (status != SA_OK) {
		e_print(saHpiEventLogInfoGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		if (info.UserEventMaxSize >= SAHPI_MAX_TEXT_BUFFER_LENGTH) {
			//We are only using text buffers for this event
			//This test could only work if the UserEventMaxSize
			// is less than the maximum text buffer size.
			retval = SAF_TEST_NOTSUPPORT;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call saHpiEventLogEntryAdd setting the DataLength variable
		//    in the text buffer to an invalid value.
		//
		EvtEntry.EventType = SAHPI_ET_USER;
		EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
		EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
		EvtEntry.Severity = SAHPI_OK;
		strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
			TEST_STRING, TEST_STRING_LENGTH);
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
		    (SaHpiUint8T) info.UserEventMaxSize + 1;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
		    SAHPI_LANG_ENGLISH;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
		    SAHPI_TL_TYPE_TEXT;

		status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
		if (status == SA_ERR_HPI_INVALID_DATA)
			retval = SAF_TEST_PASS;
		else {
			e_print(saHpiEventLogEntryAdd, SA_ERR_HPI_INVALID_DATA,
				status);
			retval = SAF_TEST_FAIL;
		}
	}

	return (retval);
}

int Resource_Test(SaHpiSessionIdT session,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {

		retval = Test_Resource(session, rpt_entry.ResourceId);
	} else {
		// This resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;
	}

	return (retval);
}

int Test_Domain(SaHpiSessionIdT session)
{
	int retval = SAF_TEST_UNKNOWN;

	// On each domain, test the domain event log.
	retval = Test_Resource(session, SAHPI_UNSPECIFIED_RESOURCE_ID);

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

	retval = process_all_domains(Resource_Test, NULL, Test_Domain);

	return (retval);
}

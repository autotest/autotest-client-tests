/*
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, Intel Corporation
 * Copyright (c) 2005, University of New Hampshire
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
 *      Donald Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryAdd
 * Description:   
 *  Call saHpiEventLogEntryAdd passing in a EvtEntry structure with 
 *  the Source set to SAHPI_UNSPECIFIED_RESOURCE_ID and the event
 *  type tried with all values except SAHPI_ET_USER.
 *  saHpiEventLogEntryAdd() returns SA_ERR_HPI_INVALID_PARAMS 
 * Line:        P51-24:P51-25
 */

#include <stdio.h>
#include "saf_test.h"
#include <string.h>

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

SaErrorT addEvent(SaHpiSessionIdT session,
		  SaHpiResourceIdT resource, SaHpiEventTypeT invalidEventType)
{
	SaHpiEventT EvtEntry;
	//
	//  Call saHpiEventLogEntryAdd passing in a EvtEntry
	//     structure with an invalid event type and
	//     the Source set to SAHPI_UNSPECIFIED_RESOURCE_ID.
	//
	EvtEntry.EventType = invalidEventType;
	EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
	EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
	EvtEntry.Severity = SAHPI_OK;
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_STRING, TEST_STRING_LENGTH);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_STRING_LENGTH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;
	return saHpiEventLogEntryAdd(session, resource, &EvtEntry);
}

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	int i;
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEventTypeT invalidEventType[] = {
		SAHPI_ET_RESOURCE, SAHPI_ET_DOMAIN,
		SAHPI_ET_SENSOR, SAHPI_ET_SENSOR_ENABLE_CHANGE,
		SAHPI_ET_HOTSWAP, SAHPI_ET_WATCHDOG,
		SAHPI_ET_HPI_SW, SAHPI_ET_OEM
	};

	for (i = 0; i < 8; i++) {
		status = addEvent(session, resource, invalidEventType[i]);
		if (status != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(addEvent, SA_ERR_HPI_INVALID_PARAMS, status);
			retval = SAF_TEST_FAIL;
			break;
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

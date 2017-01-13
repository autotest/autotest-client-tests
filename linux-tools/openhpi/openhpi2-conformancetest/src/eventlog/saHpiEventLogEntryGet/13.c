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
 * Function:    saHpiEventLogEntryGet
 * Description:   
 *   Pass a non-Null RPT entry pointer to this function.  Check whether 
 *   RptEntry->ResourceCapabilities is set to 0 and whether the Rpt entry 
 *   can be found.
 *   saHpiEventLogEntryGet() returns SA_OK.
 * Line:        P50-27:P50-29
 */
#include <stdio.h>
#include <stdlib.h>
#include "saf_test.h"

#define TEST_STRING             "Test String"
#define TEST_STRING_LENGTH      11

static void __add_user_event(SaHpiSessionIdT sessionId,
			     SaHpiResourceIdT resourceId)
{
	SaHpiEventT entry_add;
	SaErrorT status;

	entry_add.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
	entry_add.EventType = SAHPI_ET_USER;
	entry_add.Timestamp = SAHPI_TIME_UNSPECIFIED;
	entry_add.Severity = SAHPI_OK;
	memcpy(entry_add.EventDataUnion.UserEvent.UserEventData.Data,
	       TEST_STRING, sizeof(TEST_STRING));

	entry_add.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;
	entry_add.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	entry_add.EventDataUnion.UserEvent.UserEventData.DataLength =
	    (SaHpiUint8T) sizeof(TEST_STRING);

	status = saHpiEventLogEntryAdd(sessionId, resourceId, &entry_add);

	if (status != SA_OK) {
		e_print(saHpiEventAdd, SA_OK, status);
		exit(SAF_TEST_UNRESOLVED);
	}
}

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEventLogEntryIdT PrevLogEntry;
	SaHpiEventLogEntryIdT NextLogEntry;
	SaHpiEventLogEntryIdT EntryId;
	SaHpiEventLogEntryT LogEntry;
	SaHpiRdrT Rdr;
	SaHpiRptEntryT RptEntry;

	EntryId = SAHPI_OLDEST_ENTRY;
	__add_user_event(session, resource);

	while ((EntryId != SAHPI_NO_MORE_ENTRIES) &&
	       (retval == SAF_TEST_UNKNOWN)) {
		RptEntry.ResourceSeverity = SAHPI_ALL_SEVERITIES;
		RptEntry.ResourceCapabilities = (-1);
		status = saHpiEventLogEntryGet(session,
					       resource,
					       EntryId,
					       &PrevLogEntry,
					       &NextLogEntry,
					       &LogEntry, &Rdr, &RptEntry);
		if (status != SA_OK) {
			// The Get call failed in an unexpected manner
			e_print(saHpiEventLogEntryGet,
				SA_OK || SA_ERR_HPI_NOT_PRESENT, status);
			retval = SAF_TEST_FAIL;
		} else if (RptEntry.ResourceCapabilities == -1) {
			retval = SAF_TEST_FAIL;
			m_print("ResourceCapabilities is -1!");
		} else if (LogEntry.Event.EventType == SAHPI_ET_USER &&
			   RptEntry.ResourceCapabilities != 0) {
			retval = SAF_TEST_FAIL;
			m_print
			    ("ResourceCapabilities is not zero for a User Event!");
		}
		EntryId = NextLogEntry;
	}

	return (retval);
}

int Resource_Test(SaHpiSessionIdT session,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	int retval = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG)
		retval = Test_Resource(session, rpt_entry.ResourceId);
	else			// This resource does not support Event logs
		retval = SAF_TEST_NOTSUPPORT;

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

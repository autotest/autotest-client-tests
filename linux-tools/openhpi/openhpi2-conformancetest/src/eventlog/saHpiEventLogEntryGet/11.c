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
 * Authors:
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryGet
 * Description:
 *     Retrieve an entire list of entries going forward in the log.
 *     EntryId: First: SAHPI_OLDEST_ENTRY Then: returned NextEntryID Until:
 *     NextEntryID is returned is SAHPI_NO_MORE_ENTRIES.
 *     saHpiEventLogEntryGet() returns SA_OK, and the entire list of entries 
 *     is tracked forward. 
 * Line:        P50-11:50-18
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

int run_test(SaHpiSessionIdT sessionId, SaHpiResourceIdT resourceId)
{
	SaErrorT status;
	int retval = SAF_TEST_PASS;
	SaHpiEventLogEntryIdT prev_entry_id;
	SaHpiEventLogEntryIdT next_entry_id;
	SaHpiEventLogEntryIdT current_entry_id;
	SaHpiEventLogEntryT eventlog_entry;
	SaHpiRdrT rdr;
	SaHpiRptEntryT rpt_entry1;

	__add_user_event(sessionId, resourceId);

	// Since there will be at least on event in the event log, 
	// there is no way for NOT_PRESENT to be returned.

	next_entry_id = SAHPI_OLDEST_ENTRY;
	while (next_entry_id != SAHPI_NO_MORE_ENTRIES) {
		current_entry_id = next_entry_id;
		status =
		    saHpiEventLogEntryGet(sessionId, resourceId,
					  current_entry_id, &prev_entry_id,
					  &next_entry_id, &eventlog_entry, &rdr,
					  &rpt_entry1);
		if (status != SA_OK) {
			retval = SAF_TEST_FAIL;
			e_print(saHpiEventLogEntryGet, SA_OK, status);
			break;
		}
	}

	return retval;
}

int Test_Domain(SaHpiSessionIdT sessionId)
{
	return run_test(sessionId, SAHPI_UNSPECIFIED_RESOURCE_ID);
}

int Test_Resource(SaHpiSessionIdT sessionId, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resourceId = rpt_entry.ResourceId;
	int retval = SAF_TEST_NOTSUPPORT;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {
		retval = run_test(sessionId, resourceId);
	}

	return retval;
}

int main()
{
	return process_all_domains(Test_Resource, NULL, Test_Domain);
}

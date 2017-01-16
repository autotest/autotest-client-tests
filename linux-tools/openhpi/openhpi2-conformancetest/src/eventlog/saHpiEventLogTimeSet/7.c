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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *     Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogTimeSet
 * Description: 
 *  Set event log's time clock. Time > SAHPI_TIME_MAX_RELATIVE.
 *  saHpiEventLogTimeSet() returns SA_OK.
 * Line:        P55-23:P55-24
 */
#include <stdio.h>
#include <stdlib.h>
#include "saf_test.h"

// Four Seconds
#define DELTA_TIME ((SaHpiTimeT) 4000000000LL)

#define TEST_STRING             "Test String"
#define TEST_STRING_LENGTH      11

static SaErrorT __add_user_event(SaHpiSessionIdT sessionId,
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
	}

	return status;
}

/**********************************************************************************
 *
 * Verify that newly added events will have the correct timestamp.
 *
 **********************************************************************************/

int test_user_event(SaHpiSessionIdT session_id,
		    SaHpiResourceIdT resource_id, SaHpiTimeT startTime)
{
	SaErrorT status;
	int retval;
	SaHpiTimeT timestamp;
	SaHpiEventLogEntryIdT prevEntryId, nextEntryId;
	SaHpiEventLogEntryT eventLogEntry;

	status = __add_user_event(session_id, resource_id);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
	} else {
		status =
		    saHpiEventLogEntryGet(session_id, resource_id,
					  SAHPI_NEWEST_ENTRY, &prevEntryId,
					  &nextEntryId, &eventLogEntry, NULL,
					  NULL);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiEventLogEntryGet, SA_OK, status);
		} else {
			timestamp = eventLogEntry.Timestamp;
			if (timestamp >= startTime
			    && (timestamp - startTime) <= DELTA_TIME) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				m_print("User Event has the wrong timestamp!");
			}
		}
	}

	return retval;
}

int run_test(SaHpiSessionIdT session_id,
	     SaHpiResourceIdT resource_id, char *name)
{
	SaHpiTimeT time, newTime, RestoreTime;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;
	SafTimeT startTime;
	SafTimeT endTime;

	// absolute value
	time = SAHPI_TIME_MAX_RELATIVE + 1;

	// save off the time to restore later
	val = saHpiEventLogTimeGet(session_id, resource_id, &RestoreTime);
	startTime = getCurrentTime();

	if (val != SA_OK) {
		e_print(saHpiEventLogTimeGet, SA_OK, val);
		ret = SAF_TEST_UNRESOLVED;
	} else {
		val = saHpiEventLogTimeSet(session_id, resource_id, time);

		if (val == SA_ERR_HPI_INVALID_DATA) {
			ret = SAF_TEST_NOTSUPPORT;
		} else if (val != SA_OK) {
			e_print(saHpiEventLogTimeSet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
		} else {
			val =
			    saHpiEventLogTimeGet(session_id, resource_id,
						 &newTime);

			if (val != SA_OK) {
				e_print(saHpiEventLogTimeGet, SA_OK, val);
				ret = SAF_TEST_UNRESOLVED;
			} else if (newTime < SAHPI_TIME_MAX_RELATIVE) {
				ret = SAF_TEST_NOTSUPPORT;
			} else if (newTime >= time
				   && (newTime - time) <= DELTA_TIME) {
				ret =
				    test_user_event(session_id, resource_id,
						    time);
			} else {
				ret = SAF_TEST_FAIL;
				m_print
				    ("Check of new time failed to get a time that was slightly greater than or equal to time that was set. [%s]\n",
				     name);
			}
		}

		// add elapsed time before restoring it

		endTime = getCurrentTime();
		RestoreTime += ((endTime - startTime) * 1000000);

		// restore the Time before the test
		val =
		    saHpiEventLogTimeSet(session_id, resource_id, RestoreTime);
	}

	return ret;
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	return run_test(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID, "Domain");
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resource_id = rpt_entry.ResourceId;
	int ret = SAF_TEST_NOTSUPPORT;
	char name[50];

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {
		sprintf(name, "Resource %u", resource_id);
		ret = run_test(session_id, resource_id, name);
	}

	return ret;
}

/**********************************************************
 * 
 * Main Program.
 *
 * *******************************************************/
int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, Test_Domain);

	return ret;
}

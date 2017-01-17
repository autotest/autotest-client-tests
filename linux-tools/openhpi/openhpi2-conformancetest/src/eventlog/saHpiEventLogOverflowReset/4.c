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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogOverflowReset
 * Description:   
 *   Call saHpiEventLogOverflowReset on a resource or domain which does 
 *   not support overflow reset of the event log as signified by 
 *   event log info structure's OverflowResetable flag.
 *   saHpiEventLogOverflowReset() returns SA_ERR_HPI_INVALID_CMD.
 * Line:        P58-14:P58-15
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STR  "Event log test str"

int create_eventlog_overflow(SaHpiSessionIdT session_id,
			     SaHpiResourceIdT resource_id)
{

	SaHpiEventT entry_add;
	SaErrorT val;
	int i = 0;
	int size;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventLogInfoT info;

	// Create the entry to fill the log with.
	entry_add.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
	entry_add.EventType = SAHPI_ET_USER;
	entry_add.Timestamp = SAHPI_TIME_UNSPECIFIED;
	entry_add.Severity = SAHPI_OK;
	memcpy(entry_add.EventDataUnion.UserEvent.UserEventData.Data,
	       TEST_STR, sizeof(TEST_STR));
	entry_add.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;
	entry_add.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	entry_add.EventDataUnion.UserEvent.UserEventData.DataLength =
	    (SaHpiUint8T) sizeof(TEST_STR);

	val = saHpiEventLogInfoGet(session_id, resource_id, &info);
	if (val != SA_OK) {
		e_print(saHpiEventLogInfoGet, SA_OK, val);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		size = (info.Size - info.Entries) + 1;	//add one extra to create the overflow
		do {
			val =
			    saHpiEventLogEntryAdd(session_id, resource_id,
						  &entry_add);
			if (!((val == SA_OK)
			      || (val == SA_ERR_HPI_OUT_OF_SPACE))) {
				e_print(saHpiEventLogEntryAdd, SA_OK
					|| SA_ERR_HPI_OUT_OF_SPACE, val);
				retval = SAF_TEST_UNRESOLVED;
				break;
			}
			i++;
		} while (i < size);
	}

	return (retval);
}

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventLogInfoT Info;
	SaHpiBoolT savedState;

	status = saHpiEventLogStateGet(session, resource, &savedState);
	if (status != SA_OK) {
		e_print(savedState, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		status = saHpiEventLogStateSet(session, resource, SAHPI_FALSE);
		if (status != SA_OK) {
			e_print(saHpiEventLogStateSet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			// Call saHpiEventLogInfoGet
			status = saHpiEventLogInfoGet(session, resource, &Info);
			if (status != SA_OK) {
				e_print(saHpiEventLogInfoGet, SA_OK, status);
				retval = SAF_TEST_UNRESOLVED;
			} else	// The test is for when overflow is not resetable.
			{
				if (Info.OverflowResetable)
					retval = SAF_TEST_NOTSUPPORT;
			}

			if (retval != SAF_TEST_UNKNOWN)
				goto out;

			retval = create_eventlog_overflow(session, resource);
			if (retval == SAF_TEST_UNKNOWN) {
				//
				//  Call saHpiEventLogOverflowReset  
				//
				status =
				    saHpiEventLogOverflowReset(session,
							       resource);
				if (status == SA_ERR_HPI_INVALID_CMD) {
					retval = SAF_TEST_PASS;
				} else {
					retval = SAF_TEST_FAIL;
					e_print(saHpiEventLogOverflowReset,
						SA_ERR_HPI_INVALID_CMD, status);
				}
			}
			// clean up
			status = saHpiEventLogClear(session, resource);
		      out:
			status =
			    saHpiEventLogStateSet(session, resource,
						  savedState);
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

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
 *   Call saHpiEventLogEntryAdd on a resource which does
 *       not support event logs.
 *   Expected return:  call returns SA_ERR_HPI_CAPABILITY.
 * Line:        P51-17:P51-18
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	if (!(rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG)) {
		//
		//  Call saHpiEventLogEntryAdd on a resource which does
		//     not support event logs.
		//
		EvtEntry.EventType = SAHPI_ET_USER;
		EvtEntry.Severity = SAHPI_INFORMATIONAL;
		EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.Data[0] = 'A';
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength = 1;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
		    SAHPI_TL_TYPE_ASCII6;
		EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
		    SAHPI_LANG_ENGLISH;

		status = saHpiEventLogEntryAdd(session_id,
					       rpt_entry.ResourceId, &EvtEntry);
		if (status == SA_ERR_HPI_CAPABILITY) {
			retval = SAF_TEST_PASS;
		} else {
			e_print(saHpiEventLogEntryAdd, SA_ERR_HPI_CAPABILITY,
				status);
			retval = SAF_TEST_FAIL;
		}
	} else
		retval = SAF_TEST_NOTSUPPORT;
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

	retval = process_all_domains(Test_Resource, NULL, NULL);

	return (retval);
}

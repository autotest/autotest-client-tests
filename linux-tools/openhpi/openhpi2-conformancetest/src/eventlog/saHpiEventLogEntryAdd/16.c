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
 *      Liang Daming <daming.liang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryAdd
 * Description:   
 *  Call saHpiEventLogEntryAdd to test all valid text data type to check 
 *  whether all types are supported. saHpiEventLogEntryAdd() returns SA_OK.
 * Line:        P51-27:P51-29
 */
#include <stdio.h>
#include "saf_test.h"
#include <string.h>

#define TEST_STRING     "Event Test"
#define TEST_STRING_LENGTH 10

#define TEST_UNICODE "\xFF\xFE\x61\x00"
#define TEST_UNICODE_LEN 4

#define TEST_BCDPLUS "0123456789- :,_."
#define TEST_BCDPLUS_LEN 16

#define TEST_ASCII6 " 09:;?@AZ[]_"
#define TEST_ASCII6_LEN 12

#define TEST_BIN "\xFF"
#define TEST_BIN_LEN 1

int Test_Resource(SaHpiSessionIdT session, SaHpiResourceIdT resource)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiEventT EvtEntry;

	status = saHpiEventLogClear(session, resource);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiEventLogClear, SA_OK, status);
		return retval;
	}

	//
	//  Call saHpiEventLogEntryAdd passing in all valid value 
	//    Text Data Type.
	//
	EvtEntry.EventType = SAHPI_ET_USER;
	EvtEntry.Source = SAHPI_UNSPECIFIED_RESOURCE_ID;
	EvtEntry.Timestamp = SAHPI_TIME_UNSPECIFIED;
	EvtEntry.Severity = SAHPI_OK;	//non-defined value

	//Test Text Type
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_STRING, TEST_STRING_LENGTH);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_STRING_LENGTH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_TEXT;

	status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
	if (status == SA_OK)
		retval = SAF_TEST_PASS;
	else if (status == SA_ERR_HPI_OUT_OF_SPACE)
		retval = SAF_TEST_NOTSUPPORT;
	else if (status == SA_ERR_HPI_INVALID_DATA)
		retval = SAF_TEST_NOTSUPPORT;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		return retval;
	}

	//Test BCD plus Type
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_BCDPLUS, TEST_BCDPLUS_LEN);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_BCDPLUS_LEN;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_BCDPLUS;

	status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
	if (status == SA_OK)
		retval = SAF_TEST_PASS;
	else if (status == SA_ERR_HPI_OUT_OF_SPACE)
		retval = SAF_TEST_NOTSUPPORT;
	else if (status == SA_ERR_HPI_INVALID_DATA)
		retval = SAF_TEST_NOTSUPPORT;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		return retval;
	}

	//Test ASCII6 Type
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_ASCII6, TEST_ASCII6_LEN);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_ASCII6_LEN;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_ASCII6;

	status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
	if (status == SA_OK) 
		retval = SAF_TEST_PASS;
	else if (status == SA_ERR_HPI_OUT_OF_SPACE)
		retval = SAF_TEST_NOTSUPPORT;
	else if (status == SA_ERR_HPI_INVALID_DATA)
		retval = SAF_TEST_NOTSUPPORT;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		return retval;
	}

	//Test BIN Type
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_BIN, TEST_BIN_LEN);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_BIN_LEN;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_BINARY;

	status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
	if (status == SA_OK)
		retval = SAF_TEST_PASS;
	else if (status == SA_ERR_HPI_OUT_OF_SPACE)
		retval = SAF_TEST_NOTSUPPORT;
	else if (status == SA_ERR_HPI_INVALID_DATA)
		retval = SAF_TEST_NOTSUPPORT;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		return retval;
	}

	//Test Unicode
	strncpy(EvtEntry.EventDataUnion.UserEvent.UserEventData.Data,
		TEST_UNICODE, TEST_UNICODE_LEN);
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataLength =
	    TEST_UNICODE_LEN;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.Language =
	    SAHPI_LANG_ENGLISH;
	EvtEntry.EventDataUnion.UserEvent.UserEventData.DataType =
	    SAHPI_TL_TYPE_UNICODE;

	status = saHpiEventLogEntryAdd(session, resource, &EvtEntry);
	if (status == SA_OK)
		retval = SAF_TEST_PASS;
	else if (status == SA_ERR_HPI_OUT_OF_SPACE)
		retval = SAF_TEST_NOTSUPPORT;
	else if (status == SA_ERR_HPI_INVALID_DATA)
		retval = SAF_TEST_NOTSUPPORT;
	else {
		e_print(saHpiEventLogEntryAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
		return retval;
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

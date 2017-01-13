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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiEventLogEntryAdd
 * Description: 
 *  Call saHpiEventLogEntryAdd on every domain.
 *  saHpiEventLogEntryAdd() never returns SA_ERR_HPI_CAPABILITY.
 * Line:        P51-18:P51-19
 *
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

#define TEST_STR  "Event log test str"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiEventT entry_add;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

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

	val =
	    saHpiEventLogEntryAdd(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID,
				  &entry_add);
	if (val == SA_ERR_HPI_CAPABILITY) {
		e_print(saHpiEventLogEntryAdd, SA_OK, SA_ERR_HPI_CAPABILITY);
		ret = SAF_TEST_FAIL;
	} else
		ret = SAF_TEST_PASS;

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(NULL, NULL, Test_Domain);

	return ret;
}

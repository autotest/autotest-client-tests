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
 * Function:    saHpiEventLogTimeGet
 * Description: 
 *   Get the EventLog time.
 *   saHpiEventLogTimeGet() returns SA_OK.
 * Line:        P54-16:P54-16
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiTimeT time;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	val = saHpiEventLogTimeGet(session_id, SAHPI_UNSPECIFIED_RESOURCE_ID,
				   &time);
	if (val != SA_OK) {
		e_print(saHpiEventLogTimeGet, SA_OK, val);
		ret = SAF_TEST_FAIL;
	} else {
		ret = SAF_TEST_PASS;
	}

	return ret;
}

int Test_Resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		  callback2_t func)
{
	SaHpiResourceIdT resource_id = rpt_entry.ResourceId;
	SaHpiTimeT time;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_EVENT_LOG) {
		val = saHpiEventLogTimeGet(session_id, resource_id, &time);
		if (val != SA_OK) {
			e_print(saHpiEventLogTimeGet, SA_OK, val);
			m_print("Resource ID: %u", resource_id);
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	} else {
		ret = SAF_TEST_NOTSUPPORT;
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, Test_Domain);

	return ret;
}

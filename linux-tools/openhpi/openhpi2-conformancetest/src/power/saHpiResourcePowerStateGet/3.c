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
 *      Wang Jing <jing.j.wang@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiResourcePowerStateGet
 * Description:   
 *   Call saHpiResourcePowerStateGet passing a bad ResourceId.
 *   Expected return:  call returns SA_ERR_HPI_INVALID_RESOURCE
 * Line:        P29-44:P29-46
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

#define BAD_RESOURCE_ID 0xDEADBEEF

int check_powerstate(SaHpiPowerStateT state)
{
	int ret = 0;
	if (state < SAHPI_POWER_OFF || state > SAHPI_POWER_ON) {
		printf("  power state is out of range = %d\n", state);
		ret = -1;
	}
	return ret;
}

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiPowerStateT state_old;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;
	SaHpiResourceIdT bad_ID = BAD_RESOURCE_ID;
	resource_id = rpt_entry.ResourceId;
	if (resource_id == bad_ID)
		bad_ID++;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_POWER) {
		val = saHpiResourcePowerStateGet(session_id,
						 bad_ID, &state_old);
		if (val != SA_ERR_HPI_INVALID_RESOURCE) {
			e_print(saHpiResourcePowerStateGet,
				SA_ERR_HPI_INVALID_RESOURCE, val);
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}

	} else {
		// Resource Does not support Power Management
		ret = SAF_TEST_NOTSUPPORT;
	}

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}

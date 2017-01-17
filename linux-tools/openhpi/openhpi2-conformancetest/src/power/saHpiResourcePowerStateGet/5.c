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
 *   Call saHpiResourcePowerStateGet passing NULL as State.
 *   Expected return:  call returns SA_ERR_HPI_INVALID_PARAMS
 * Line:        P158-20:P158-21
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

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
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	resource_id = rpt_entry.ResourceId;
	if ((rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_POWER)) {
		val = saHpiResourcePowerStateGet(session_id, resource_id, NULL);
		if (val != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(saHpiResourcePowerStateGet,
				SA_ERR_HPI_INVALID_PARAMS, val);
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

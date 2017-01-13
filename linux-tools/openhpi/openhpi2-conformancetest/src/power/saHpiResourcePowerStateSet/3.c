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
 * Function:    saHpiResourcePowerStateSet
 * Description:   
 *   Call saHpiResourcePowerStateSet to set power state same as the old state.
 *   Expected return:  call returns SA_OK 
 * Line:        P157-5
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

#define HPI_TEST_RETRY_COUNT  8

int check_powerstate(SaHpiPowerStateT state)
{
	int ret = 0;
	if (state < SAHPI_POWER_OFF || state > SAHPI_POWER_ON) {
		printf("  power state is out of range = %d\n", state);
		ret = -1;
	}
	return ret;
}

int try_get_powerstate(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
		       SaHpiPowerStateT * state)
{
	int retry = 0;
	SaErrorT val;
	int ret = SA_OK;
	for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
		val = saHpiResourcePowerStateGet(session_id,
						 resource_id, state);
		if (val != SA_ERR_HPI_BUSY) {
			if (val != SA_OK) {
				e_print(saHpiResourcePowerStateGet, SA_OK, val);
				ret = SAF_TEST_FAIL;
			}
			break;
		}
		sleep(1);
	}
	if (retry >= HPI_TEST_RETRY_COUNT) {
		printf
		    ("  Function \"saHpiResourcePowerStateGet\" works abnormally!\n");
		printf("  Timeout on getting power status!\n");
		printf("  Return value: %s \n", get_error_string(val));
		ret = SAF_TEST_FAIL;
	}
	return ret;

}

int try_set_powerstate(SaHpiSessionIdT session_id, SaHpiResourceIdT resource_id,
		       SaHpiPowerStateT state)
{
	int retry = 0;
	SaErrorT val;
	int ret = SA_OK;
	for (retry = 0; retry < HPI_TEST_RETRY_COUNT; retry++) {
		val = saHpiResourcePowerStateSet(session_id,
						 resource_id, state);
		if (val != SA_ERR_HPI_BUSY) {
			if (val != SA_OK) {
				e_print(saHpiResourcePowerStateSet, SA_OK, val);
				ret = SAF_TEST_FAIL;
			}
			break;
		}
		sleep(1);
	}
	if (retry >= HPI_TEST_RETRY_COUNT) {
		printf
		    ("  Function \"saHpiResourcePowerStateSet\" works abnormally!\n");
		printf("  Timeout on setting power status!\n");
		printf("  Return value: %s \n", get_error_string(val));
		ret = SAF_TEST_FAIL;
	}
	return ret;

}

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiPowerStateT state, state_old;
	int ret = SAF_TEST_UNKNOWN;

	resource_id = rpt_entry.ResourceId;
	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_POWER) {
		if (try_get_powerstate(session_id, resource_id, &state_old) !=
		    SA_OK) {
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}
		if (try_set_powerstate(session_id, resource_id, state_old) !=
		    SA_OK) {
			ret = SAF_TEST_FAIL;
			goto out;
		}
		sleep(32);
		if (try_get_powerstate(session_id, resource_id, &state) !=
		    SA_OK) {
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}
		if (state != state_old) {
			e_print(saHpiResourcePowerStateSet, state_old, state);
			ret = SAF_TEST_FAIL;

		}

	} else {
		// Resource Does not support Power Management
		ret = SAF_TEST_NOTSUPPORT;
	}
      out:

	if (ret == SAF_TEST_UNKNOWN)
		ret = SAF_TEST_PASS;

	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(Test_Resource, NULL, NULL);

	return ret;
}

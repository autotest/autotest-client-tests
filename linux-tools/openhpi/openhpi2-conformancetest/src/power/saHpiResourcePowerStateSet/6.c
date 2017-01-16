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
 *   Call saHpiResourcePowerStateSet on resource which does't support POWER capability.
 *   Expected return:  call returns SA_ERR_HPI_CAPABILITY
 * Line:        P159-20:P159-21
 */
#include <stdio.h>
#include <unistd.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session_id,
		  SaHpiRptEntryT rpt_entry, callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	resource_id = rpt_entry.ResourceId;
	if (!(rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_POWER)) {
		val = saHpiResourcePowerStateSet(session_id,
						 resource_id, SAHPI_POWER_ON);
		if (val != SA_ERR_HPI_CAPABILITY) {
			e_print(saHpiResourcePowerStateSet,
				SA_ERR_HPI_CAPABILITY, val);
			ret = SAF_TEST_FAIL;

		} else
			ret = SAF_TEST_PASS;

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

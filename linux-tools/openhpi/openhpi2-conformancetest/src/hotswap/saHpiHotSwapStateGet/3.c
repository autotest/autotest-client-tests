/*      -*- linux-c -*-
 *
 * Copyright (c) 2005 by Intel Corp.
 * (C) Copyright IBM Corp. 2004, 2005
 *
 *   This program is free software; you can redistribute it and/or modify 
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or 
 *   (at your option) any later version.
 *   This program is distributed in the hope that it will be useful, 
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *   GNU General Public License for more details. 
 *   You should have received a copy of the GNU General Public License 
 *   along with this program; if not, write to the Free Software 
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 
 *   USA 
 *
 * Author(s):
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiHotSwapStateGet
 * Description:
 *   Obtain the current hot swap state of each resource.
 *   saHpiHotSwapStateGet() returns SA_OK.
 * Line:        P147-18:P147-18
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int process_resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		     callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiHsStateT state;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {

		resource_id = rpt_entry.ResourceId;

		val = saHpiHotSwapStateGet(session_id, resource_id, &state);
		if (val != SA_OK) {
			e_print(saHpiHotSwapStateGet, SA_OK, val);
			ret = SAF_TEST_FAIL;
		}

		if (ret == SAF_TEST_UNKNOWN) {
			if (state == SAHPI_HS_STATE_NOT_PRESENT) {
				e_print(saHpiHotSwapStateGet,
					state != SAHPI_HS_STATE_NOT_PRESENT,
					val);
				ret = SAF_TEST_FAIL;
			} else
				ret = SAF_TEST_PASS;
		}
	} else {
		// If not a HotSwap Resource
		ret = SAF_TEST_NOTSUPPORT;
	}
	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(process_resource, NULL, NULL);

	return ret;
}

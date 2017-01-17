/*      -*- linux-c -*-
 *
 * Copyright (c) 2003 by Intel Corp.
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
 * Function:    saHpiHotSwapIndicatorStateSet
 * Description:
 *   Set the state of the hot swap indicator associated with the 
 *   specified resource.
 *   state = SAHPI_HS_INDICATOR_OFF.
 *   saHpiHotSwapIndicatorStateSet() returns SA_OK.
 * Line:        P150-20:P150-20
 *    
 */
#include <stdio.h>
#include "saf_test.h"
int process_resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		     callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiHsIndicatorStateT state_new, state_old;
	SaErrorT val;
	int ret = SAF_TEST_NOTSUPPORT;

	if (rpt_entry.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {
		if (!(rpt_entry.HotSwapCapabilities &
		      SAHPI_HS_CAPABILITY_INDICATOR_SUPPORTED)) {
			// Hot Swap Indicator not supported
			ret = SAF_TEST_NOTSUPPORT;
		}
	} else {
		// Not a Hot Swap supported Resource
		ret = SAF_TEST_NOTSUPPORT;
	}
	if (ret == SAF_TEST_UNKNOWN) {
		resource_id = rpt_entry.ResourceId;

		val = saHpiHotSwapIndicatorStateGet(session_id, resource_id,
						    &state_old);
		if (val != SA_OK) {
			e_print(saHpiHotSwapIndicatorStateGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		val = saHpiHotSwapIndicatorStateSet(session_id, resource_id,
						    SAHPI_HS_INDICATOR_OFF);
		if (val != SA_OK) {
			e_print(saHpiHotSwapIndicatorStateSet, SA_OK, val);
			ret = SAF_TEST_FAIL;
			goto out;
		}

		val = saHpiHotSwapIndicatorStateGet(session_id, resource_id,
						    &state_new);
		if (val != SA_OK) {
			e_print(saHpiHotSwapIndicatorStateGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		if (state_new != SAHPI_HS_INDICATOR_OFF) {
			e_print(saHpiHotSwapIndicatorStateGet,
				SAHPI_HS_INDICATOR_OFF, state_new);
			ret = SAF_TEST_FAIL;
		} else
			ret = SAF_TEST_PASS;
	      out1:
		// Clean-up restore
		val = saHpiHotSwapIndicatorStateSet(session_id, resource_id,
						    state_old);
	}
      out:
	return ret;
}

int main()
{
	int ret = SAF_TEST_PASS;

	ret = process_all_domains(process_resource, NULL, NULL);

	return ret;
}

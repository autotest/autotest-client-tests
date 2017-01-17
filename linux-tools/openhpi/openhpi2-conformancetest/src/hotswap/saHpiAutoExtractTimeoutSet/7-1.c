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
 * Function:    saHpiAutoExtractTimeoutSet
 * Description:
 *   Configure a timeout for how long to wait before the 
 *   default auto-extraction poilicy is involked. Timeout = 
 *   SAHPI_TIMEOUT_IMMEDIATE.  This is a 
 *   Read/Write/Read/Compare/Restore test.
 *   saHpiAutoExtractTimeoutSet() returns SA_OK.
 * Line:        P145-26:P145-31
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int process_resource(SaHpiSessionIdT session_id, SaHpiRptEntryT rpt_entry,
		     callback2_t func)
{
	SaHpiResourceIdT resource_id;
	SaHpiTimeoutT timeout_new, timeout_old;
	SaErrorT val;
	int ret = SAF_TEST_UNKNOWN;

	if ((!(rpt_entry.HotSwapCapabilities &
	       SAHPI_HS_CAPABILITY_AUTOEXTRACT_READ_ONLY)) &&
	    (rpt_entry.ResourceCapabilities &
	     SAHPI_CAPABILITY_MANAGED_HOTSWAP)) {

		resource_id = rpt_entry.ResourceId;

		val = saHpiAutoExtractTimeoutGet(session_id, resource_id,
						 &timeout_old);
		if (val != SA_OK) {
			e_print(saHpiAutoExtractTimeoutGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out;
		}

		val = saHpiAutoExtractTimeoutSet(session_id, resource_id,
						 SAHPI_TIMEOUT_IMMEDIATE);
		if (val != SA_OK) {
			e_print(saHpiAutoExtractTimeoutSet, SA_OK, val);
			ret = SAF_TEST_FAIL;
			goto out;
		}

		val = saHpiAutoExtractTimeoutGet(session_id, resource_id,
						 &timeout_new);
		if (val != SA_OK) {
			e_print(saHpiAutoExtractTimeoutGet, SA_OK, val);
			ret = SAF_TEST_UNRESOLVED;
			goto out1;
		}

		if (timeout_new != SAHPI_TIMEOUT_IMMEDIATE) {
			m_print
			    ("Function \"saHpiAutoExtractTimeoutSet\" works abnormally!\n"
			     "Got timeout value which differs from that was set just now.");
			ret = SAF_TEST_FAIL;
		} else {
			ret = SAF_TEST_PASS;
		}
	      out1:
		// Clean up
		val = saHpiAutoExtractTimeoutSet(session_id, resource_id,
						 timeout_old);
	} else {
		// Not a Hot Swap supported Resource
		ret = SAF_TEST_NOTSUPPORT;
	}
      out:
	return ret;
}

int main()
{
	int ret = SAF_TEST_UNKNOWN;

	ret = process_all_domains(process_resource, NULL, NULL);

	return ret;
}

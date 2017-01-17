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
 * Function:    saHpiAutoInsertTimeoutSet
 * Description:
 *   Pass in a Timeout value equal to SAHPI_TIMEOUT_BLOCK.
 *   saHpiAutoInsertTimeoutSet() returns SA_OK.
 * Line:        P142-22:P142-30
 *    
 */
#include <stdio.h>
#include "saf_test.h"
#define INSERT_TIMEOUT_VALUE    1000
int ForEachDomain(SaHpiSessionIdT session_id)
{
	SaHpiTimeoutT timeout_new, timeout_old;
	SaErrorT val;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiDomainInfoT DomainInfo;

	val = saHpiDomainInfoGet(session_id, &DomainInfo);
	if (val != SA_OK) {
		e_print(saHpiDomainInfoGet, SA_OK, val);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		if (DomainInfo.DomainCapabilities &
		    SAHPI_DOMAIN_CAP_AUTOINSERT_READ_ONLY) {
			// Domain does not have auto-insert
			// write capability
			retval = SAF_TEST_NOTSUPPORT;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		val = saHpiAutoInsertTimeoutGet(session_id, &timeout_old);
		if (val != SA_OK) {
			e_print(saHpiAutoInsertTimeoutGet, SA_OK, val);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		val =
		    saHpiAutoInsertTimeoutSet(session_id, SAHPI_TIMEOUT_BLOCK);
		if (val != SA_OK) {
			e_print(saHpiAutoInsertTimeoutSet, SA_OK, val);
			retval = SAF_TEST_FAIL;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		val = saHpiAutoInsertTimeoutGet(session_id, &timeout_new);
		if (val != SA_OK) {
			e_print(saHpiAutoInsertTimeoutGet, SA_OK, val);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (timeout_new != SAHPI_TIMEOUT_BLOCK) {
				m_print
				    ("Function \"saHpiAutoInsertTimeoutSet\" works abnormally!\n"
				     "\tThe Retrieved timeout does not matched what was set!");
				retval = SAF_TEST_FAIL;
			} else
				retval = SAF_TEST_PASS;
		}
		// Clean up
		val = saHpiAutoInsertTimeoutSet(session_id, timeout_old);
	}

	return (retval);
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successful
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(NULL, NULL, ForEachDomain);

	return (retval);
}

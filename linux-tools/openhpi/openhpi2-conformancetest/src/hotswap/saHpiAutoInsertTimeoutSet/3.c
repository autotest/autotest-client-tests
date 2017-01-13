/*      -*- linux-c -*-
 *
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
 *      Carl McAdams <carlmc@us.ibm.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAutoInsertTimeoutSet
 * Description:
 *   Call on a domain which has SAHPI_DOMAIN_CAP_AUTPINSERT_READ_ONLY 
 *   flag in the DomainInfo structure.
 *   saHpiAutoInsertTimeoutSet() returns SA_ERR_HPI_READ_ONLY.
 * Line:        P142-17:P142-18
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int ForEachDomain(SaHpiSessionIdT session_id)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiDomainInfoT DomainInfo;

	status = saHpiDomainInfoGet(session_id, &DomainInfo);
	if (status != SA_OK) {
		e_print(saHpiDomainInfoGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		if (!(DomainInfo.DomainCapabilities &
		      SAHPI_DOMAIN_CAP_AUTOINSERT_READ_ONLY)) {
			// Domain does have auto-insert
			// write capability
			retval = SAF_TEST_NOTSUPPORT;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call the function on a domain which the 
		//  auto-insert is fixed with the 
		//  SAHPI_DOMAIN_CAP_AUTOINSERT_READ_ONLY 
		//  flag in the DomainInfo Structure.
		//
		status =
		    saHpiAutoInsertTimeoutSet(session_id, SAHPI_TIMEOUT_BLOCK);
		if (status != SA_ERR_HPI_READ_ONLY) {
			e_print(saHpiAutoInsertTimeoutSet,
				SA_ERR_HPI_READ_ONLY, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
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

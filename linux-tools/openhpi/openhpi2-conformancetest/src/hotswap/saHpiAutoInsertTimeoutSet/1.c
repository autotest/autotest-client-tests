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
 *   Pass in an invalid SessionID.
 *   saHpiAutoInsertTimeoutSet() returns SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 *    
 */
#include <stdio.h>
#include "saf_test.h"

#define BAD_SESSION_ID 0xDEADBEEF

int ForEachDomain(SaHpiSessionIdT session_id)
{
	SaHpiTimeoutT Timeout = SAHPI_TIMEOUT_BLOCK;
	SaHpiSessionIdT badId;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiDomainInfoT DomainInfo;

	status = saHpiDomainInfoGet(session_id, &DomainInfo);
	if (status != SA_OK) {
		e_print(saHpiDomainInfoGet, SA_OK, status);
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
		//
		// rule out the 1::4000000000 chance that this is a valid id
		//
		badId = BAD_SESSION_ID;
		if (session_id == badId)
			badId++;
		//
		//  Call saHpiAutoInsertTimeoutSet passing in a bad SessionId
		//
		status = saHpiAutoInsertTimeoutSet(badId, Timeout);
		if (status != SA_ERR_HPI_INVALID_SESSION) {
			e_print(saHpiAutoInsertTimeoutSet,
				SA_ERR_HPI_INVALID_SESSION, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS_AND_EXIT;
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

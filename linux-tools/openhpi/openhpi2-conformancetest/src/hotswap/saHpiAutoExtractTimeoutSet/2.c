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
 * Function:    saHpiAutoExtractTimeoutGet
 * Description:
 *   Pass in an invalid SessionID.
 *   saHpiAutoExtractTimeoutSet() returns SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 *    
 */
#include <stdio.h>
#include "saf_test.h"

#define BAD_SESSION_ID 0xDEADBEEF

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSessionIdT bad_ID;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {
		if (report.HotSwapCapabilities &
		    SAHPI_HS_CAPABILITY_AUTOEXTRACT_READ_ONLY) {
			// Cannot set the auto extract timeout
			retval = SAF_TEST_NOTSUPPORT;
		}
	} else {
		// Not a Hot Swap supported Resource
		retval = SAF_TEST_NOTSUPPORT;
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		// rule out the 1::4000000000 chance that this is a valid id
		//
		bad_ID = BAD_SESSION_ID;
		if (session == bad_ID)
			bad_ID++;
		//
		//  Call saHpiAutoExtractTimeoutSet passing in a bad SessionId
		//
		status = saHpiAutoExtractTimeoutSet(bad_ID,
						    report.ResourceId,
						    SAHPI_TIMEOUT_IMMEDIATE);
		if (status != SA_ERR_HPI_INVALID_SESSION) {
			e_print(saHpiAutoExtractTimeoutSet,
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

	retval = process_all_domains(Test_Resource, NULL, NULL);

	return (retval);
}

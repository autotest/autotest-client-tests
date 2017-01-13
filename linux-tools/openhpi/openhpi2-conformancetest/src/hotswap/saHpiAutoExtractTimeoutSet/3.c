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
 * Function:    saHpiAutoExtractTimeoutSet
 * Description:
 *   Set the AutoExtractTimeout for all resources.
 *   saHpiAutoExtractTimeoutSet() returns SA_OK.
 * Line:        P145-18:P145-18
 *    
 */
#include <stdio.h>
#include "saf_test.h"

#define ONE_SECOND_TIMEOUT 1000000000

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiTimeoutT Timeout_Save;
	SaHpiTimeoutT Timeout;
	SaHpiBoolT RestoreTimeout = SAHPI_FALSE;

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
		//  Save off AutoExtractTimeout
		//
		status = saHpiAutoExtractTimeoutGet(session,
						    report.ResourceId,
						    &Timeout_Save);
		if (status != SA_OK) {
			e_print(saHpiAutoExtractTimeoutGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call saHpiAutoExtractTimeoutSet setting it to a new value
		//
		status = saHpiAutoExtractTimeoutSet(session, report.ResourceId, ONE_SECOND_TIMEOUT);	//1 sec in nano seconds
		if (status != SA_OK) {
			e_print(saHpiAutoExtractTimeoutSet, SA_OK, status);
			retval = SAF_TEST_FAIL;
		} else
			RestoreTimeout = SAHPI_TRUE;
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Retrieve the AutoExtractTimeout value set
		//
		status = saHpiAutoExtractTimeoutGet(session,
						    report.ResourceId,
						    &Timeout);
		if (status != SA_OK) {
			e_print(saHpiAutoExtractTimeoutGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		}
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Compare the AutoExtractValue retieved with the value set.
		//
		if (Timeout != ONE_SECOND_TIMEOUT) {
			m_print
			    ("Function \"saHpiAutoExtractTimeoutSet\" works abnormally!\n"
			     "\tCompare of AutoExtractTimeout Set verses the Get failed!");
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
	}
	//
	// clean up
	//
	if (RestoreTimeout != SAHPI_FALSE) {
		//
		//  Restore the AutoExtractTimeout value
		//
		status = saHpiAutoExtractTimeoutSet(session,
						    report.ResourceId,
						    Timeout_Save);
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

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
 *   Call against a resoruce which the auto-extract timeout is fixed 
 *   with the SAHPI_HS_CAPABILITY_AUTOEXTRACT_READ_ONLY flag in the 
 *   resource's RPT entry.
 *   saHpiAutoExtractTimeoutSet() returns SA_ERR_HPI_READ_ONLY.
 * Line:        P145-23:P145-24
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {
		if (!(report.HotSwapCapabilities &
		      SAHPI_HS_CAPABILITY_AUTOEXTRACT_READ_ONLY)) {
			// Can set the auto extract timeout
			retval = SAF_TEST_NOTSUPPORT;
		}
	} else {
		// Not a Hot Swap supported Resource
		retval = SAF_TEST_NOTSUPPORT;
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call the saHpiAutoExtractTimeoutSet on 
		//  a resource which does not support 
		//  AutoExtractTimeout writes.
		//
		status = saHpiAutoExtractTimeoutSet(session,
						    report.ResourceId,
						    SAHPI_TIMEOUT_IMMEDIATE);
		if (status != SA_ERR_HPI_READ_ONLY) {
			e_print(saHpiAutoExtractTimeoutSet,
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

	retval = process_all_domains(Test_Resource, NULL, NULL);

	return (retval);
}

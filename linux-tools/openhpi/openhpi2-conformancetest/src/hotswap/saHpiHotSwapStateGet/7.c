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
 * Function:    saHpiHotSwapStateGet
 * Description:
 *   Obtain the current hot swap state of each resource. Make sure 
 *   that Not Present state is never returned.
 *   saHpiHotSwapStateGet() returns SA_OK.
 * Line:        P147-28:P147-29
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiHsStateT State;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {
		//
		//  Call saHpiHotSwapStateGet
		//
		status = saHpiHotSwapStateGet(session,
					      report.ResourceId, &State);
		if (status != SA_OK) {
			e_print(saHpiHotSwapStateGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
		} else {
			if (State == SAHPI_HS_STATE_NOT_PRESENT) {
				e_print(saHpiHotSwapStateGet,
					State != SAHPI_HS_STATE_NOT_PRESENT,
					status);
				retval = SAF_TEST_FAIL;
			} else
				retval = SAF_TEST_PASS;
		}
	} else			//Resource does not support hot swap
		retval = SAF_TEST_NOTSUPPORT;
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

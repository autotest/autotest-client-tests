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
 * Function:    saHpiHotSwapIndicatorStateGet
 * Description:
 *   Get the current Hot Swap Indicator state for each resource.
 *   Compare the returned result to make sure it is only off or on.
 *   saHpiHotSwapIndicatorStateGet() returns SA_OK.
 * Line:        P149-27:P149-28
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Resource(SaHpiSessionIdT session,
		  SaHpiRptEntryT report, callback2_t func)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiHsIndicatorStateT State;

	if (report.ResourceCapabilities & SAHPI_CAPABILITY_MANAGED_HOTSWAP) {
		if (!(report.HotSwapCapabilities &
		      SAHPI_HS_CAPABILITY_INDICATOR_SUPPORTED)) {
			// Hot Swap Indicator not supported
			retval = SAF_TEST_NOTSUPPORT;
		}
	} else {
		// Not a Hot Swap supported Resource
		retval = SAF_TEST_NOTSUPPORT;
	}
	if (retval == SAF_TEST_UNKNOWN) {
		//
		//  Call saHpiHotSwapIndicatorStateGet.
		//
		status = saHpiHotSwapIndicatorStateGet(session,
						       report.ResourceId,
						       &State);
		if (status != SA_OK) {
			e_print(saHpiHotSwapIndicatorStateGet, SA_OK, status);
			retval = SAF_TEST_FAIL;
		} else {
			if ((State == SAHPI_HS_INDICATOR_OFF) ||
			    (State == SAHPI_HS_INDICATOR_ON)) {
				retval = SAF_TEST_PASS;
			} else {
				m_print
				    ("Function \"saHpiHotSwapIndicatorStateGet\" works abnormally!\n"
				     "\tInvalid state value returned!\n"
				     "\tReturned State value: %d", State);
				retval = SAF_TEST_FAIL;
			}
		}
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

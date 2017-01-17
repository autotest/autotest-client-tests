/*      -*- linux-c -*-
 *
 * (C) Copyright IBM Corp. 2004, 2005
 * (C) Copyright Intel Corp. 2005
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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAcknowledge
 * Description:
 *      Call the function passing in an bad Severity. 
 *      saHpiAlarmAcknowledge returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P70-18:P70-19
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaErrorT status;
	// all severity values that're not legal for alarms
	SaHpiSeverityT severity[] = {
		SAHPI_OK + 1,
		SAHPI_DEBUG - 1,
		SAHPI_DEBUG + 1,
		SAHPI_ALL_SEVERITIES - 1,
		SAHPI_ALL_SEVERITIES + 1,
		0
	};
	int retval = SAF_TEST_UNKNOWN;
	int index;

	retval = SAF_TEST_PASS;
	for (index = 0; severity[index]; ++index) {
		//Call the function passing in an bad Severity.
		status = saHpiAlarmAcknowledge(session_id,
					                   SAHPI_ENTRY_UNSPECIFIED,
					                   severity[index]);
		if (status != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(saHpiAlarmAcknowledge,
                    SA_ERR_HPI_INVALID_PARAMS, status);
			retval = SAF_TEST_FAIL;
			break;
		}
	}

	return retval;
}

/**********************************************************
*   Main Function
*      takes no arguments
*      
*       returns: SAF_TEST_PASS when successfull
*                SAF_TEST_FAIL when an unexpected error occurs
*************************************************************/
int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(NULL, NULL, Test_Domain);

	return (retval);
}

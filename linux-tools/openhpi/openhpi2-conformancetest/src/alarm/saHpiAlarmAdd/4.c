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
 * Function:    saHpiAlarmAdd
 * Description:
 *      Call the function passing in a bad severity in the alarm
 *      structure.
 *      saHpiAlarmAdd() returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P72-14:P72-15
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int run_test(SaHpiSessionIdT session_id, SaHpiSeverityT bad_severity)
{
	SaHpiAlarmT NewAlarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Create a new Alarm
	//
	NewAlarm.Severity = bad_severity;
	NewAlarm.Acknowledged = SAHPI_FALSE;
	NewAlarm.AlarmCond.Type = SAHPI_STATUS_COND_TYPE_USER;
	NewAlarm.AlarmCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
	NewAlarm.AlarmCond.Data.Language = SAHPI_LANG_ENGLISH;
	NewAlarm.AlarmCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
	NewAlarm.AlarmCond.Data.DataLength = 1;
	NewAlarm.AlarmCond.Data.Data[0] = 'a';
	NewAlarm.AlarmCond.DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID;
	NewAlarm.AlarmCond.Name.Length = 4;
	NewAlarm.AlarmCond.Name.Value[0] = 'T';
	NewAlarm.AlarmCond.Name.Value[1] = 'e';
	NewAlarm.AlarmCond.Name.Value[2] = 's';
	NewAlarm.AlarmCond.Name.Value[3] = 't';

	status = saHpiAlarmAdd(session_id, &NewAlarm);

	if (status != SA_ERR_HPI_INVALID_PARAMS) {
		e_print(saHpiAlarmAdd, SA_ERR_HPI_INVALID_PARAMS, status);
		retval = SAF_TEST_FAIL;

		// Clean up
		if (status == SA_OK)
			saHpiAlarmDelete(session_id, NewAlarm.AlarmId, 0);
	} else
		retval = SAF_TEST_PASS;

	return retval;
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	int i;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT bad_severity[] =
	    { SAHPI_INFORMATIONAL, SAHPI_OK, SAHPI_OK + 1,
		SAHPI_DEBUG, SAHPI_ALL_SEVERITIES
	};

	for (i = 0; i < 5; i++) {
		retval = run_test(session_id, bad_severity[i]);
		if (retval != SAF_TEST_PASS) {
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

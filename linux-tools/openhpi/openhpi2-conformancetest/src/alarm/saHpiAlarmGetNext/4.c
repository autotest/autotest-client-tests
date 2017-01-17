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
 * Function:    saHpiAlarmGetNext
 * Description:
 *      Call saHpiAlarmGetNext() passing in a NULL Alarm pointer.
 *      saHpiAlarmGetNext() returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P67-23:P67-23
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Create a new Alarm
	//
	Alarm.Severity = SAHPI_MINOR;
	Alarm.Acknowledged = SAHPI_FALSE;
	Alarm.AlarmCond.Type = SAHPI_STATUS_COND_TYPE_USER;
	Alarm.AlarmCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
	Alarm.AlarmCond.Data.Language = SAHPI_LANG_ENGLISH;
	Alarm.AlarmCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
	Alarm.AlarmCond.Data.DataLength = 1;
	Alarm.AlarmCond.Data.Data[0] = 'a';
	Alarm.AlarmCond.DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID;
	Alarm.AlarmCond.Name.Length = 4;
	Alarm.AlarmCond.Name.Value[0] = 'T';
	Alarm.AlarmCond.Name.Value[1] = 'e';
	Alarm.AlarmCond.Name.Value[2] = 's';
	Alarm.AlarmCond.Name.Value[3] = 't';

	status = saHpiAlarmAdd(session_id, &Alarm);

	if (status != SA_OK) {
		// Unable to create a new alarm
		e_print(saHpiAlarmAdd, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		// When the Alarm is successfully set

		//
		//  Call saHpiAlarmGetNext() passing in a NULL 
		//  Alarm pointer.
		//

		status = saHpiAlarmGetNext(session_id,
					   SAHPI_MINOR, SAHPI_FALSE, NULL);
		if (status != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(saHpiAlarmGetNext,
				SA_ERR_HPI_INVALID_PARAMS, status);
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
		// Clean up
		status = saHpiAlarmDelete(session_id, Alarm.AlarmId, 0);
	}

	return (retval);
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

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
 * Function:    saHpiAlarmGet
 * Description:
 *      Attempt to get the last alarm using SAHPI_LAST_ENTRY 
 *      as the AlarmId.  The implementation should return
 *      SA_OK or SA_ERR_HPI_NOT_PRESENT.  Either return code
 *      is valid since the specification is ambiguous.
 * Line:        P69-20:P69-21
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm, NewAlarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	//
	// Create a new Alarm
	//
	NewAlarm.Severity = SAHPI_MINOR;
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

	if (status != SA_OK) {
		// Unable to create a new alarm
		e_print(saHpiAlarmAdd, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		// When the Alarm is successfully set

		status = saHpiAlarmGet(session_id, SAHPI_LAST_ENTRY, &Alarm);
		if (status != SA_OK) {
			if (status == SA_ERR_HPI_NOT_PRESENT) {
				//It is unclear whether this should work.
				retval = SAF_TEST_PASS;
			} else {
				e_print(saHpiAlarmGet,
					SA_ERR_HPI_NOT_PRESENT, status);
				retval = SAF_TEST_FAIL;
			}
		} else {
			if (Alarm.AlarmId == SAHPI_LAST_ENTRY) {
				m_print
				    ("Function \"saHpiAlarmGet\": AlarmID is matching SAHPI_LAST_ENTRY!");
				retval = SAF_TEST_FAIL;
			} else {
				// Alarm Found and alarmid is not 
				// set to SAHPI_LAST_ENTRY
				retval = SAF_TEST_PASS;
			}
		}
		// Clean up
		status = saHpiAlarmDelete(session_id, NewAlarm.AlarmId, 0);
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

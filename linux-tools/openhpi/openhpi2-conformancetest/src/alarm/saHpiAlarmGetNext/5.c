/*      -*- linux-c -*-
 *
 * (C) Copyright IBM Corp. 2004, 2005
 * Copyright (c) 2005, University of New Hampshire
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmGetNext
 * Description:
 *      Call the function passing in an Alarm Structure with a 
 *      mis-matching AlarmId and Timestamp.
 *      saHpiAlarmGetNext() returns SA_ERR_HPI_INVALID_DATA.
 * Line:        P67-29:P67-30
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm, NewAlarm;
	SaHpiAlarmIdT FirstAlarm, SecondAlarm;
	SaHpiTimeT FirstAlarmTime, SecondAlarmTime;
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
	NewAlarm.AlarmCond.Name.Length = 6;
	NewAlarm.AlarmCond.Name.Value[0] = 'T';
	NewAlarm.AlarmCond.Name.Value[1] = 'e';
	NewAlarm.AlarmCond.Name.Value[2] = 's';
	NewAlarm.AlarmCond.Name.Value[3] = 't';
	NewAlarm.AlarmCond.Name.Value[4] = ' ';
	NewAlarm.AlarmCond.Name.Value[5] = '1';

	status = saHpiAlarmAdd(session_id, &NewAlarm);

	if (status != SA_OK) {
		// Unable to create a new alarm
		e_print(saHpiAlarmAdd, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
	} else {
		// When the Alarm is successfully set

		FirstAlarm = NewAlarm.AlarmId;
		FirstAlarmTime = NewAlarm.Timestamp;

		// We want to sleep for 2 seconds because we want to
		// guarantee that the timestamp for the second alarm
		// is not the same as the first alarm.  If we didn't
		// sleep, there is a danger that the two timestamps
		// would be the same due to clock accuracy.
		//
		sleep(2);

		// create the second alarm
		NewAlarm.Severity = SAHPI_MAJOR;
		NewAlarm.AlarmId = 0;
		NewAlarm.Timestamp = 0;
		NewAlarm.AlarmCond.Name.Value[5] = '2';
		NewAlarm.AlarmCond.Data.Data[0] = 'b';
		status = saHpiAlarmAdd(session_id, &NewAlarm);
		if (status != SA_OK) {
			e_print(saHpiAlarmAdd, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			// In the very unlikely event that the two timestamps
			// are same (despite the sleep), then don't bother
			// doing this test.
			if (FirstAlarmTime == NewAlarm.Timestamp) {
				m_print
				    ("The first and second timestamps are the same!");
				retval = SAF_TEST_NOTSUPPORT;
			} else {
				SecondAlarm = NewAlarm.AlarmId;
				SecondAlarmTime = NewAlarm.Timestamp;

				// Look for an alarm which has a mis-matching time and alarmId.
				// 
				Alarm.AlarmId = FirstAlarm;
				Alarm.Timestamp = SecondAlarmTime;

				status = saHpiAlarmGetNext(session_id,
							   SAHPI_ALL_SEVERITIES,
							   SAHPI_FALSE, &Alarm);
				if (status != SA_ERR_HPI_INVALID_DATA) {
					e_print(saHpiAlarmGetNext,
						SA_ERR_HPI_INVALID_DATA,
						status);
					retval = SAF_TEST_FAIL;
				} else {
					retval = SAF_TEST_PASS;
				}
			}
			// Clean up
			status = saHpiAlarmDelete(session_id, FirstAlarm, 0);
			status = saHpiAlarmDelete(session_id, SecondAlarm, 0);
		}
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

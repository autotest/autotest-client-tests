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
 *      Add two new user alarms to each domain, and make sure that it 
 *      could be read.  Clean up by erasing the user alarms created.
 *      saHpiAlarmGetNext() returns SA_OK.  The first Alarm set 
 *      will be the first alarm returned.  Both Alarms will be returned.
 * Line:        P67-32:P67-32
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm, NewAlarm;
	SaHpiAlarmIdT FirstAlarm, SecondAlarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiBoolT FirstAlarmFound = SAHPI_FALSE;

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

		// create the second alarm
		NewAlarm.AlarmId = 0;
		NewAlarm.Timestamp = 0;
		NewAlarm.AlarmCond.Name.Value[5] = '2';
		NewAlarm.AlarmCond.Data.Data[0] = 'b';
		status = saHpiAlarmAdd(session_id, &NewAlarm);
		if (status != SA_OK) {
			e_print(saHpiAlarmAdd, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {

			SecondAlarm = NewAlarm.AlarmId;
			// Loop through the alarms to find the one
			// which we just set
			Alarm.AlarmId = SAHPI_FIRST_ENTRY;
			status = SA_OK;
			while (status == SA_OK) {
				status = saHpiAlarmGetNext(session_id,
							   SAHPI_ALL_SEVERITIES,
							   SAHPI_FALSE, &Alarm);
				if (status == SA_ERR_HPI_NOT_PRESENT) {
					//end of list
					break;
				}
				if (status != SA_OK) {
					e_print(saHpiAlarmGetNext,
						SA_OK, status);
					retval = SAF_TEST_FAIL;
					break;
				}
				if (Alarm.AlarmId == FirstAlarm) {
					if (FirstAlarmFound == SAHPI_FALSE)
						FirstAlarmFound = SAHPI_TRUE;
					else {
						m_print
						    ("Function \"saHpiAlarmGetNext\" returned the same alarm twice!");
						retval = SAF_TEST_FAIL;
						break;
					}
				}
				if (Alarm.AlarmId == SecondAlarm) {
					if (FirstAlarmFound == SAHPI_FALSE) {
						m_print
						    ("Function \"saHpiAlarmGetNext\" returned the alarms out of order!");
						retval = SAF_TEST_FAIL;
						break;
					} else {
						// Alarm Found after first one found
						retval = SAF_TEST_PASS;
						break;
					}
				}
			}
			// Clean up
			status = saHpiAlarmDelete(session_id, SecondAlarm, 0);
			if (retval == SAF_TEST_UNKNOWN) {
				// The second new alarm was never found.
				m_print
				    ("Function \"saHpiAlarmGetNext\" failed to return both of the newly created alarms!");
				retval = SAF_TEST_FAIL;
			}
		}
		status = saHpiAlarmDelete(session_id, FirstAlarm, 0);
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

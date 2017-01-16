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
 *      Get all unacknowledged alarms of a severity equal to Major.
 *      saHpiAlarmGetNext() returns SA_OK.
 * Line:        P67-37:P67-37
 *
 */
#include <stdio.h>
#include "saf_test.h"

// The alarm count is actually the number of different severities
// that can be used for user alarms.
#define ALARM_COUNT  3

/*********************************************************************************
 * Initialize an Alarm with a given severity.
 *
 * Note that the AlarmId is set to UNSPECIFIED.  This will be used to determine
 * if the alarm was added to the DAT or not.  An alarm that is added to the DAT
 * will have a valid AlarmId, i.e. not UNSPECIFIED.
 * *******************************************************************************/

void initAlarm(SaHpiAlarmT * alarm, SaHpiSeverityT severity)
{
	alarm->AlarmId = SAHPI_ENTRY_UNSPECIFIED;
	alarm->Severity = severity;
	alarm->Acknowledged = SAHPI_FALSE;
	alarm->AlarmCond.Type = SAHPI_STATUS_COND_TYPE_USER;
	alarm->AlarmCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
	alarm->AlarmCond.Data.Language = SAHPI_LANG_ENGLISH;
	alarm->AlarmCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
	alarm->AlarmCond.Data.DataLength = 1;
	alarm->AlarmCond.Data.Data[0] = 'a';
	alarm->AlarmCond.DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID;
	alarm->AlarmCond.Name.Length = 4;
	alarm->AlarmCond.Name.Value[0] = 'T';
	alarm->AlarmCond.Name.Value[1] = 'e';
	alarm->AlarmCond.Name.Value[2] = 's';
	alarm->AlarmCond.Name.Value[3] = 't';
}

/*********************************************************************************
 * Add a set of acknowledged and unacknowledged alarms with different severities
 * to the DAT.  In other words, the following six alarms will be added.
 *
 *          Severity    Acknowledged
 *          --------    ------------
 *          MINOR       Yes
 *          MAJOR       Yes
 *          CRITICAL    Yes
 *          MINOR       No
 *          MAJOR       No
 *          CRITICAL    No
 *
 * *******************************************************************************/

int addAlarms(SaHpiSessionIdT session_id, SaHpiAlarmT ackAlarm[],
	      SaHpiAlarmT unackAlarm[])
{
	int i;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT severity[] =
	    { SAHPI_MINOR, SAHPI_MAJOR, SAHPI_CRITICAL };

	// Initialize the Alarms to be added with the three severity levels.

	for (i = 0; i < ALARM_COUNT; i++) {
		initAlarm(&(ackAlarm[i]), severity[i]);
		initAlarm(&(unackAlarm[i]), severity[i]);
	}

	// Add the acknowledged alarms.  Note that alarms are actually acknowledged
	// after being added.

	for (i = 0; i < ALARM_COUNT && retval == SAF_TEST_UNKNOWN; i++) {
		status = saHpiAlarmAdd(session_id, &(ackAlarm[i]));
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAlarmAdd, SA_OK, status);
		} else {
			status =
			    saHpiAlarmAcknowledge(session_id,
						  ackAlarm[i].AlarmId,
						  SAHPI_ENTRY_UNSPECIFIED);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiAlarmAcknowledge, SA_OK, status);
			}
		}
	}

	// Add the unacknowledged alarms.

	for (i = 0; i < ALARM_COUNT && retval == SAF_TEST_UNKNOWN; i++) {
		status = saHpiAlarmAdd(session_id, &(unackAlarm[i]));
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAlarmAdd, SA_OK, status);
		}
	}

	return retval;
}

/*********************************************************************************
 * Remove the given set of alarms.  If the alarm's AlarmId is UNSPECIFIED
 * this indicates that the alarm was never added to the DAT.  In that case,
 * don't bother trying to delete the alarm from the DAT.
 * *******************************************************************************/

void removeAlarms(SaHpiSessionIdT session_id, SaHpiAlarmT alarm[])
{
	int i;
	SaErrorT status;

	for (i = 0; i < ALARM_COUNT; i++) {
		if (alarm[i].AlarmId != SAHPI_ENTRY_UNSPECIFIED) {
			status =
			    saHpiAlarmDelete(session_id, alarm[i].AlarmId,
					     SAHPI_ENTRY_UNSPECIFIED);
			if (status != SA_OK) {
				e_print(saHpiAlarmDelete, SA_OK, status);
			}
		}
	}
}

/*********************************************************************************
 * Does the given AlarmId match one of alarms in the given set of alarms?
 * *******************************************************************************/

SaHpiBoolT isAlarm(SaHpiAlarmIdT alarmId, SaHpiAlarmT alarm[])
{
	int i;
	SaHpiBoolT found = SAHPI_FALSE;

	for (i = 0; i < ALARM_COUNT && !found; i++) {
		if (alarm[i].AlarmId == alarmId) {
			found = SAHPI_TRUE;
		}
	}

	return found;
}

/*********************************************************************************
 * Test saHpiAlarmGetNext function by reading all of the unacknowledged alarms
 * of severity Major from the DAT.  To adequately test this, six alarms will be
 * added to the DAT.  The first three alarms will be acknowledged and use the
 * three valid severities.  The second three alarms will be unacknowledged and
 * use the three valid severities.  If the function works properly, only the
 * unacknowledged alarm of severity Major should be returned.
 *********************************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	int count = 0;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiAlarmT alarm, ackAlarm[ALARM_COUNT], unackAlarm[ALARM_COUNT];

	//
	// Add the acknowledged and unacknowledged alarms.
	// 

	retval = addAlarms(session_id, ackAlarm, unackAlarm);

	if (retval == SAF_TEST_UNKNOWN) {
		// 
		// Retrieve all of the unacknowledged alarms with the Severity
		// equal to Major from all of the domains.
		// 

		alarm.AlarmId = SAHPI_FIRST_ENTRY;
		status = SA_OK;

		while (status == SA_OK) {
			status = saHpiAlarmGetNext(session_id,
						   SAHPI_MAJOR,
						   SAHPI_TRUE, &alarm);

			if (status == SA_ERR_HPI_NOT_PRESENT) {
				//end of list
				break;
			} else if (status != SA_OK) {
				e_print(saHpiAlarmGetNext, SA_OK, status);
				retval = SAF_TEST_FAIL;
				break;
			} else if (alarm.Severity != SAHPI_MAJOR) {
				m_print
				    ("Function \"saHpiAlarmGetNext\" returned an alarm of a different severity!");
				m_print
				    ("Expected severity: SAHPI_MAJOR; Returned severity: %d",
				     alarm.Severity);
				retval = SAF_TEST_FAIL;
			} else if (alarm.Acknowledged != SAHPI_FALSE) {
				m_print
				    ("Function \"saHpiAlarmGetNext\": an acknowledged alarm was returned instead!");
				retval = SAF_TEST_FAIL;
				break;
			} else if (isAlarm(alarm.AlarmId, unackAlarm)) {
				count++;
			}
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		if (count != 1) {
			m_print
			    ("Function \"saHpiAlarmGetNext\" did not return the user alarms of severity SAHPI_MAJOR!");
			retval = SAF_TEST_FAIL;
		} else
			retval = SAF_TEST_PASS;
	}
	//
	// Remove all of the user alarms that were added.
	// 
	removeAlarms(session_id, ackAlarm);
	removeAlarms(session_id, unackAlarm);

	return retval;
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
	return process_all_domains(NULL, NULL, Test_Domain);
}

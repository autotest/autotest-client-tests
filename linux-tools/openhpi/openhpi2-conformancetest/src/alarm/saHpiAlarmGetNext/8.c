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
 *      Get all alarms of a specific severity.
 *      saHpiAlarmGetNext() returns SA_OK.
 * Line:        P67-37:P67-37
 *
 */
#include <stdio.h>
#include "saf_test.h"

// The alarm count is actually the number of different severities
// that can be used for user alarms.
#define ALARM_COUNT 6

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

int addAlarms(SaHpiSessionIdT session_id, SaHpiAlarmT alarm[])
{
	int i;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT severity[] = { SAHPI_MINOR, SAHPI_MAJOR, SAHPI_CRITICAL,
		SAHPI_MINOR, SAHPI_MAJOR, SAHPI_CRITICAL
	};
	SaHpiBoolT ack[] = { SAHPI_TRUE, SAHPI_TRUE, SAHPI_TRUE,
		SAHPI_FALSE, SAHPI_FALSE, SAHPI_FALSE
	};

	// Initialize the Alarms to be added with the three severity levels.

	for (i = 0; i < ALARM_COUNT; i++) {
		initAlarm(&(alarm[i]), severity[i]);
	}

	// Add the alarms and acknowledge some of them.

	for (i = 0; i < ALARM_COUNT && retval == SAF_TEST_UNKNOWN; i++) {
		status = saHpiAlarmAdd(session_id, &(alarm[i]));
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAlarmAdd, SA_OK, status);
		} else if (ack[i]) {
			status =
			    saHpiAlarmAcknowledge(session_id, alarm[i].AlarmId,
						  SAHPI_ENTRY_UNSPECIFIED);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				e_print(saHpiAlarmAcknowledge, SA_OK, status);
			}
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
 * Run a test for a specific severity.  Only read the alarms with the given
 * severity.  If we get an alarm with a different severity, this is an obvious
 * error.  We must also make sure that we get two alarms from the "alarmList".
 * If we don't see the two alarms we added with the given severity, then clearly
 * we have an error.
 * *******************************************************************************/

int run_test(SaHpiSessionIdT sessionid, SaHpiSeverityT severity,
	     SaHpiAlarmT alarmList[])
{
	int count = 0;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiAlarmT alarm;

	//
	//  Retrieve all of the alarms from all of the domains.
	//
	alarm.AlarmId = SAHPI_FIRST_ENTRY;
	status = SA_OK;
	while (status == SA_OK) {

		status = saHpiAlarmGetNext(sessionid, severity,
					   SAHPI_FALSE, &alarm);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			//end of list
			break;
		} else if (status != SA_OK) {
			e_print(saHpiAlarmGetNext, SA_OK, status);
			retval = SAF_TEST_FAIL;
			break;
		} else if (alarm.Severity != severity) {
			m_print
			    ("Function \"saHpiAlarmGetNext\" returned an alarm of a different severity!");
			m_print("Expected severity: %d; Returned severity: %d",
				severity, alarm.Severity);
			retval = SAF_TEST_FAIL;
		} else if (isAlarm(alarm.AlarmId, alarmList)) {
			count++;
		}
	}

	if (retval == SAF_TEST_UNKNOWN) {
		if (count != 2) {
			m_print
			    ("Function \"saHpiAlarmGetNext\" did not return the user alarms of severity %d!",
			     severity);
			retval = SAF_TEST_FAIL;
		}
	}

	return retval;
}

/*********************************************************************************
 * To adequately test this function, we must add six alarms as indicated in the
 * above comments.  We will attempt to only read the alarms for a specific severity
 * and we will read acknowledged and unacknowledged alarms for that severity.
 * *******************************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	int i;
	SaHpiAlarmT alarmList[ALARM_COUNT];
	int retval = SAF_TEST_UNKNOWN;
	SaHpiSeverityT severity[] =
	    { SAHPI_MINOR, SAHPI_MAJOR, SAHPI_CRITICAL };

	retval = addAlarms(session_id, alarmList);

	// Try all three severities.
	for (i = 0; i < 3 && retval == SAF_TEST_UNKNOWN; i++) {
		retval = run_test(session_id, severity[i], alarmList);
	}

	// If nothing bad has happened, then everything must have gone well.
	if (retval == SAF_TEST_UNKNOWN) {
		retval = SAF_TEST_PASS;
	}

	removeAlarms(session_id, alarmList);

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
	return process_all_domains(NULL, NULL, Test_Domain);
}

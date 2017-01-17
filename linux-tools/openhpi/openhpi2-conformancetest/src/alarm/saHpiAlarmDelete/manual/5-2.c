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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmDelete
 * Description:
 *      If a non-user alarm exist, create a user alarm with the same severity
 *      Attempt to delete all of the alarms with that severity.
 *      saHpiAlarmDelete() returns SA_OK. The non-user alarm is not removed.
 * Line:        P73-24:P73-25
 *    
 */

#include <stdio.h>
#include "saf_test.h"

#define HPI_TEST_RETRY_MAX  30	// re-try 30 times

/************************************************************************
 *
 * Add a User Alarm to the DAT.
 *
 ************************************************************************/

SaErrorT add_user_alarm(SaHpiSessionIdT sessionId,
			SaHpiSeverityT severity, SaHpiAlarmT * NewAlarm)
{
	SaErrorT status;

	NewAlarm->Severity = severity;
	NewAlarm->AlarmCond.Type = SAHPI_STATUS_COND_TYPE_USER;
	NewAlarm->AlarmCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
	NewAlarm->AlarmCond.Data.Language = SAHPI_LANG_ENGLISH;
	NewAlarm->AlarmCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
	NewAlarm->AlarmCond.Data.DataLength = 1;
	NewAlarm->AlarmCond.Data.Data[0] = 'a';
	NewAlarm->AlarmCond.DomainId = SAHPI_UNSPECIFIED_DOMAIN_ID;
	NewAlarm->AlarmCond.Name.Length = 4;
	NewAlarm->AlarmCond.Name.Value[0] = 'T';
	NewAlarm->AlarmCond.Name.Value[1] = 'e';
	NewAlarm->AlarmCond.Name.Value[2] = 's';
	NewAlarm->AlarmCond.Name.Value[3] = 't';

	status = saHpiAlarmAdd(sessionId, NewAlarm);

	if (status != SA_OK) {
		e_print(saHpiAlarmAdd, SA_OK, status);
	}

	return status;
}

/************************************************************************
 *
 * Find a System (non-user) alarm in the DAT.
 *
 ************************************************************************/

int find_system_alarm(SaHpiSessionIdT sessionId, SaHpiAlarmT * alarm)
{
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;

	alarm->AlarmId = SAHPI_FIRST_ENTRY;
	while (SAHPI_TRUE) {
		status = saHpiAlarmGetNext(sessionId,
					   SAHPI_ALL_SEVERITIES,
					   SAHPI_FALSE, alarm);

		if (status == SA_ERR_HPI_NOT_PRESENT) {
			break;
		} else if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiAlarmGetNext, SA_OK, status);
		} else if (alarm->AlarmCond.Type != SAHPI_STATUS_COND_TYPE_USER) {
			retval = SAF_TEST_PASS;
		}
	}

	return retval;
}

/************************************************************************
 *
 * Wait for a System Alarm to be generated.
 *
 ************************************************************************/

int wait_for_system_alarm(SaHpiSessionIdT sessionId, SaHpiAlarmT * alarm)
{
	int retval = SAF_TEST_UNKNOWN;
	int retryCount = HPI_TEST_RETRY_MAX;

	read_prompt
	    ("Please generate a System/Hardware alarm and then press Enter to continue.");

	do {
		retval = find_system_alarm(sessionId, alarm);
		if (retval == SAF_TEST_UNKNOWN) {
			retryCount--;
			sleep(2);
		}
	} while (retval == SAF_TEST_UNKNOWN && retryCount > 0);

	return retval;
}

/************************************************************************
 *
 * Test deleting user alarms of a specific severity and verify that
 * system alarms of the same severity were not deleted.
 *
 ************************************************************************/

int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaHpiAlarmT NewAlarm, systemAlarm, Alarm;
	SaErrorT status;
	int retval;

	retval = find_system_alarm(sessionId, &systemAlarm);
	if (retval == SAF_TEST_UNKNOWN) {
		retval = wait_for_system_alarm(sessionId, &systemAlarm);
	}

	if (retval == SAF_TEST_UNKNOWN) {
		retval = SAF_TEST_NOTSUPPORT;
		m_print("Did not find a System Alarm!");
	} else if (retval == SAF_TEST_PASS) {
		status =
		    add_user_alarm(sessionId, systemAlarm.Severity, &NewAlarm);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
		} else {

			status = saHpiAlarmDelete(sessionId,
						  SAHPI_ENTRY_UNSPECIFIED,
						  systemAlarm.Severity);
			if (status != SA_OK) {
				retval = SAF_TEST_FAIL;
				e_print(saHpiAlarmDelete, SA_OK, status);
			} else {

				status = saHpiAlarmGet(sessionId,
						       systemAlarm.AlarmId,
						       &Alarm);

				if (status == SA_OK) {
					retval = SAF_TEST_PASS;
				} else if (status == SA_ERR_HPI_NOT_PRESENT) {
					retval = SAF_TEST_FAIL;
					m_print
					    ("Function \"saHpiAlarmDelete\" deleted a non-user alarm!");
				} else {
					retval = SAF_TEST_UNRESOLVED;
					e_print(saHpiAlarmGet,
						SA_OK | SA_ERR_HPI_NOT_PRESENT,
						status);
				}
			}
		}
	}

	return retval;
}

/************************************************************************
 *
 * Main Program
 *
 ************************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(NULL, NULL, Test_Domain);
}

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
 *      Attempt to get the next alarm from the DAT
 *      using an alarm that was deleted.
 * Line:        P67-32:P67-35
 *    
 */

#include <stdio.h>
#include "saf_test.h"

/*************************************************************************
 * Add an alarm to the DAT.
 * ***********************************************************************/

SaErrorT addAlarm(SaHpiSessionIdT session_id, SaHpiAlarmT * alarm)
{
	SaErrorT status;

	alarm->Severity = SAHPI_MINOR;
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

	status = saHpiAlarmAdd(session_id, alarm);
	if (status != SA_OK) {
		e_print(saHpiAlarmAdd, SA_OK, status);
	}

	return status;
}

/*************************************************************************
 * Delete an alarm from the DAT.
 * ***********************************************************************/

SaErrorT deleteAlarm(SaHpiSessionIdT session_id, SaHpiAlarmIdT alarm_id)
{
	SaErrorT status;

	status = saHpiAlarmDelete(session_id, alarm_id, SAHPI_ALL_SEVERITIES);
	if (status != SA_OK) {
		e_print(saHpiAlarmDelete, SA_OK, status);
	}
	return status;
}

/*************************************************************************
 * Find an alarm, identified by "alarm_id2", in the DAT.  Start the 
 * traversal of the DAT at the given alarm.  
 * ***********************************************************************/

SaErrorT findAlarm(SaHpiSessionIdT session_id,
		   SaHpiAlarmT alarm,
		   SaHpiAlarmIdT alarm_id2, SaHpiBoolT * found)
{
	SaErrorT status = SA_OK;

	*found = SAHPI_FALSE;
	while (status == SA_OK) {
		status =
		    saHpiAlarmGetNext(session_id, SAHPI_ALL_SEVERITIES,
				      SAHPI_FALSE, &alarm);
		if (status == SA_ERR_HPI_NOT_PRESENT) {
			// do nothing; loop will exit
		} else if (status != SA_OK) {
			e_print(saHpiAlarmGetNext, SA_OK, status);
		} else if (alarm_id2 == alarm.AlarmId) {
			*found = SAHPI_TRUE;
		}
	}

	return status;
}

/*************************************************************************
 * Test saHpiAlarmGetNext.  We should be able to delete an alarm and still
 * use that alarm information to get the next alarm in the DAT.  To test
 * this, two user alarms will be added to the DAT.  The first alarm will
 * then be deleted.  Traversal of the DAT will begin with that deleted
 * alarm and we will search the DAT for the second alarm.  While we would 
 * expect the second alarm to immediately follow the deleted alarm, that 
 * might not be the case due to race conditions with system alarms.  Because 
 * of this we will simply traverse the DAT until we find the second alarm 
 * if it is there.
 * ***********************************************************************/

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT alarm1, alarm2;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiBoolT found = SAHPI_FALSE;

	status = addAlarm(session_id, &alarm1);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
	} else {
		status = addAlarm(session_id, &alarm2);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			deleteAlarm(session_id, alarm1.AlarmId);
		} else {
			status = deleteAlarm(session_id, alarm1.AlarmId);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
			} else {
				status =
				    findAlarm(session_id, alarm1,
					      alarm2.AlarmId, &found);
				if (status != SA_ERR_HPI_NOT_PRESENT) {
					retval = SAF_TEST_UNRESOLVED;
				} else if (found) {
					retval = SAF_TEST_PASS;
				} else {	// not found
					m_print
					    ("Function \"saHpiAlarmGetNext\" did not find second alarm after deleting first alarm.");
					retval = SAF_TEST_FAIL;
				}
			}
			deleteAlarm(session_id, alarm2.AlarmId);
		}
	}

	return retval;
}

/******************************************************************
 *  Main Program
 *      
 *       returns: SAF_TEST_PASS when successfull
 *                SAF_TEST_FAIL when an unexpected error occurs
 ******************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(NULL, NULL, Test_Domain);
}

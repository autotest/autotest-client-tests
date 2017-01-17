/*      -*- linux-c -*-
 *
 * Copyright (c) 2005, Intel Corporation
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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmGetNext
 * Description:
 *      Retrieve all of the alarms from all of the domains. Make
 *      sure that the AlarmId's never match SAHPI_LAST_ENTRY or
 *      SAHPI_FIRST_ENTRY.
 *      saHpiAlarmGetNext() returns SA_OK.
 * Line:        P68-7:P68-8
 *    
 */
#include <stdio.h>
#include "saf_test.h"

static const int ALARM_NUMBER = 2;

/*************************************************************************
 * Add an alarm to the DAT.
 * ***********************************************************************/

void addAlarm(SaHpiSessionIdT session_id, SaHpiAlarmT * alarm)
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
		exit(SAF_TEST_UNRESOLVED);
	}
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

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiAlarmIdT AlarmId[ALARM_NUMBER];
	int idx;

	//
	//  Add alarms so there is something to read back
	//
	for (idx = 0; idx < ALARM_NUMBER; ++idx) {
		addAlarm(session_id, &Alarm);
		AlarmId[idx] = Alarm.AlarmId;
	}

	//
	//  Retrieve all of the alarms from all of the domains.
	//
	Alarm.AlarmId = SAHPI_FIRST_ENTRY;
	status = SA_OK;
	while (status == SA_OK) {
		status = saHpiAlarmGetNext(session_id,
					   SAHPI_ALL_SEVERITIES,
					   SAHPI_FALSE, &Alarm);
		if (status == SA_ERR_HPI_NOT_PRESENT)
			break;	//end of list

		if (status != SA_OK) {
			e_print(saHpiAlarmGetNext, SA_OK, status);
			retval = SAF_TEST_FAIL;
			break;
		}
		if ((Alarm.AlarmId == SAHPI_FIRST_ENTRY) ||
		    (Alarm.AlarmId == SAHPI_LAST_ENTRY)) {
			m_print
			    ("Function \"saHpiAlarmGetNext\": AlarmId is set to a reserved AlarmId value!");
			m_print("AlarmId value: %s\n",
				(Alarm.AlarmId ==
				 SAHPI_FIRST_ENTRY ? "SAHPI_FIRST_ENTRY" :
				 "SAHPI_LAST_ENTRY"));
			retval = SAF_TEST_FAIL;
		}
	}

	//
	//  Cleanup all alarms we added
	//
	idx--;
	while (idx >= 0) {
		deleteAlarm(session_id, AlarmId[idx]);
		--idx;
	}

	if (retval == SAF_TEST_UNKNOWN)
		retval = SAF_TEST_PASS;

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

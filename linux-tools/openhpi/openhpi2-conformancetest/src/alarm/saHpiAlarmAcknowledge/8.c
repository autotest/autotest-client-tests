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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAcknowledge
 * Description:
 *      Acknowledge all alarms.
 *      saHpiAlarmAcknowledge() returns SA_OK.
 * Line:        P70-28:P70-29
 *    
 */
#include <stdio.h>
#include "saf_test.h"

#define SEVERITY_NUM    3

static __inline__ void __add_alarm(SaHpiSessionIdT session_id,
				   SaHpiAlarmT * NewAlarm,
				   SaHpiSeverityT severity)
{
	SaErrorT status;

	NewAlarm->Severity = severity;
	NewAlarm->Acknowledged = SAHPI_FALSE;
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

	status = saHpiAlarmAdd(session_id, NewAlarm);
	if (status != SA_OK) {
		// Unable to create a new alarm
		e_print(saHpiAlarmAdd, SA_OK, status);
		exit(SAF_TEST_UNRESOLVED);
	}
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT Alarm, NewAlarm[SEVERITY_NUM];
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	int idx;
	int alarmCount = 0;
	SaHpiSeverityT severity[SEVERITY_NUM] = {
		SAHPI_CRITICAL,
		SAHPI_MAJOR,
		SAHPI_MINOR,
	};

	for (idx = 0; idx < SEVERITY_NUM; ++idx) {
		__add_alarm(session_id, &NewAlarm[idx], severity[idx]);
		alarmCount++;
	}

	// When the Alarms are successfully added
	status = saHpiAlarmAcknowledge(session_id,
				       SAHPI_ENTRY_UNSPECIFIED,
				       SAHPI_ALL_SEVERITIES);
	if (status != SA_OK) {
		e_print(saHpiAlarmAcknowledge, SA_OK, status);
		retval = SAF_TEST_FAIL;
		goto out;
	}

	for (idx = 0; idx < SEVERITY_NUM; ++idx) {
		status =
		    saHpiAlarmGet(session_id, NewAlarm[idx].AlarmId, &Alarm);
		if (status != SA_OK) {
			e_print(saHpiAlarmGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
			goto out;
		}

		if (Alarm.Acknowledged == SAHPI_FALSE) {
			m_print
			    ("Function failed to acknowledgement the alarm!");
			retval = SAF_TEST_FAIL;
			goto out;
		}
	}

	retval = SAF_TEST_PASS;

      out:
	// Clean up
	for (idx = 0; idx < alarmCount; idx++) {
		status = saHpiAlarmDelete(session_id,
					  NewAlarm[idx].AlarmId,
					  SAHPI_ALL_SEVERITIES);
		if (status != SA_OK)
			e_print(saHpiAlarmDelete, SA_OK, status);
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

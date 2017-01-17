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
 * Function:    saHpiAlarmAdd
 * Description:
 *      In each domain, create an user alarm and remove it.
 *      saHpiAlarmAdd() returns SA_OK.
 * Line:        P72-12:P72-12
 *    
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"
/*
 *  0 if the same, otherwise return -1.
 */
static int __compare_alarm(const SaHpiAlarmT * alarm_a,
			   const SaHpiAlarmT * alarm_b)
{
	if (alarm_a->Severity != alarm_b->Severity) {
		m_print("Severity doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Type != alarm_b->AlarmCond.Type) {
		m_print("AlarmCond.Type doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.ResourceId != alarm_b->AlarmCond.ResourceId) {
		m_print("AlarmCond.ResourceId doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Data.Language !=
	    alarm_b->AlarmCond.Data.Language) {
		m_print("AlarmCond.Data.Language doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Data.DataType !=
	    alarm_b->AlarmCond.Data.DataType) {
		m_print("AlarmCond.Data.DataType doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Data.DataLength !=
	    alarm_b->AlarmCond.Data.DataLength) {
		m_print("AlarmCond.Data.DataLength doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Data.Data[0] != alarm_b->AlarmCond.Data.Data[0]) {
		m_print("AlarmCond.Data.Data[0] doesn't match");
		return -1;
	}

	if (alarm_a->AlarmCond.Name.Length != alarm_b->AlarmCond.Name.Length) {
		m_print("AlarmCond.Name.Length doesn't match");
		return -1;
	}

	if (memcmp(alarm_a->AlarmCond.Name.Value,
		   alarm_b->AlarmCond.Name.Value,
		   alarm_b->AlarmCond.Name.Length)) {
		m_print("AlarmCond.Name.Value doesn't match");
		return -1;
	}

	return 0;
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT NewAlarm;
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
	NewAlarm.AlarmCond.Name.Length = 4;
	NewAlarm.AlarmCond.Name.Value[0] = 'T';
	NewAlarm.AlarmCond.Name.Value[1] = 'e';
	NewAlarm.AlarmCond.Name.Value[2] = 's';
	NewAlarm.AlarmCond.Name.Value[3] = 't';

	status = saHpiAlarmAdd(session_id, &NewAlarm);

	if (status != SA_OK) {
		e_print(saHpiAlarmAdd, SA_OK, status);
		retval = SAF_TEST_FAIL;
	} else {
		SaHpiAlarmT Alarm;
		// verify that what we get back is "our" alarm
		status = saHpiAlarmGet(session_id, NewAlarm.AlarmId, &Alarm);
		if (status != SA_OK) {
			e_print(saHpiAlarmGet, SA_OK, status);
			retval = SAF_TEST_UNRESOLVED;
		} else {
			if (!__compare_alarm(&NewAlarm, &Alarm))
				retval = SAF_TEST_PASS;
			else
				retval = SAF_TEST_FAIL;

			// Clean up
			status = saHpiAlarmDelete(session_id,
						  NewAlarm.AlarmId, 0);
			if (status != SA_OK)
				e_print(saHpiAlarmDelete, SA_OK, status);
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

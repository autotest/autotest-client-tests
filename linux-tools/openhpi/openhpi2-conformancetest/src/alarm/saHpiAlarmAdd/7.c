/*      -*- linux-c -*-
 *
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
 *      Qun Li <qun.li@intel.com>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAdd
 * Description:
 *      In each domain, create an user alarm and remove it.
 *      Verify that enumerations and other fields are valid.
 *      saHpiAlarmAdd() returns SA_OK.
 * Line:        P188-1:P188-44
 *    
 */
#include <stdio.h>
#include <string.h>
#include "saf_test.h"

static __inline__ SaHpiBoolT __alarm_is_valid(const SaHpiAlarmT * alarm)
{
	if (!((alarm->Severity >= SAHPI_CRITICAL && alarm->Severity <= SAHPI_OK)
	      || (alarm->Severity == SAHPI_DEBUG)
	      || (alarm->Severity == SAHPI_ALL_SEVERITIES)))
		return SAHPI_FALSE;

	if (!(alarm->AlarmCond.Type >= SAHPI_STATUS_COND_TYPE_SENSOR &&
	      alarm->AlarmCond.Type <= SAHPI_STATUS_COND_TYPE_USER))
		return SAHPI_FALSE;

	if (alarm->AlarmCond.Name.Length > SA_HPI_MAX_NAME_LENGTH)
		return SAHPI_FALSE;

	if (alarm->AlarmCond.Data.DataLength > SAHPI_MAX_TEXT_BUFFER_LENGTH)
		return SAHPI_FALSE;

	if (!(alarm->AlarmCond.Data.DataType >= SAHPI_TL_TYPE_UNICODE
	      && alarm->AlarmCond.Data.DataType <= SAHPI_TL_TYPE_BINARY))
		return SAHPI_FALSE;

	if (!(alarm->AlarmCond.Data.Language >= SAHPI_LANG_UNDEF
	      && alarm->AlarmCond.Data.Language <= SAHPI_LANG_ZULU))
		return SAHPI_FALSE;

	return SAHPI_TRUE;
}

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT NewAlarm, Alarm;
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
		goto out;
	}
	// verify that what we get back is "our" alarm
	status = saHpiAlarmGet(session_id, NewAlarm.AlarmId, &Alarm);
	if (status != SA_OK) {
		e_print(saHpiAlarmGet, SA_OK, status);
		retval = SAF_TEST_UNRESOLVED;
		goto out;
	}

	if (__alarm_is_valid(&Alarm))
		retval = SAF_TEST_PASS;
	else
		retval = SAF_TEST_FAIL;

	// Clean up
	status = saHpiAlarmDelete(session_id, NewAlarm.AlarmId, 0);
	if (status != SA_OK)
		e_print(saHpiAlarmDelete, SA_OK, status);

      out:
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

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
 *      Add a new user alarm and test the returned value for AlarmId 
 *      and Timestamp.
 *      saHpiAlarmAdd() returns SA_OK and the AlarmId and the Timestamp
 *      are set to a new value.
 * Line:        P72-21:P72-22
 *    
 */
#include <stdio.h>
#include "saf_test.h"

#define PAIRS   2

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT NewAlarm;
	SaErrorT status;
	int cnt;
	int retval = SAF_TEST_UNKNOWN;

	struct {
		SaHpiAlarmIdT AlarmId;
		SaHpiTimeT Timestamp;
	} test_pairs[PAIRS] = {
		{
		SAHPI_ENTRY_UNSPECIFIED, SAHPI_TIME_UNSPECIFIED}, {
		(-1), (-1)}
	};

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
	NewAlarm.AlarmCond.Name.Length = 4;
	NewAlarm.AlarmCond.Name.Value[0] = 'T';
	NewAlarm.AlarmCond.Name.Value[1] = 'e';
	NewAlarm.AlarmCond.Name.Value[2] = 's';
	NewAlarm.AlarmCond.Name.Value[3] = 't';

	for (cnt = 0; cnt < PAIRS; ++cnt) {
		SaHpiAlarmIdT AlarmId = test_pairs[cnt].AlarmId;
		SaHpiTimeT Timestamp = test_pairs[cnt].Timestamp;
		NewAlarm.AlarmId = AlarmId;
		NewAlarm.Timestamp = Timestamp;
		status = saHpiAlarmAdd(session_id, &NewAlarm);

		if (status != SA_OK) {
			e_print(saHpiAlarmAdd, SA_OK, status);
			retval = SAF_TEST_FAIL;
		} else {
			// Clean up
			status =
			    saHpiAlarmDelete(session_id, NewAlarm.AlarmId, 0);
			if (status != SA_OK)
				e_print(saHpiAlarmDelete, SA_OK, status);

			if ((NewAlarm.AlarmId != AlarmId)
			    && (NewAlarm.Timestamp != Timestamp)) {
				retval = SAF_TEST_PASS;
			} else {
				e_print(saHpiAlarmAdd,
					NewAlarm.AlarmId != AlarmId
					&& NewAlarm.Timestamp != Timestamp,
					status);
				retval = SAF_TEST_FAIL;
				break;
			}
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

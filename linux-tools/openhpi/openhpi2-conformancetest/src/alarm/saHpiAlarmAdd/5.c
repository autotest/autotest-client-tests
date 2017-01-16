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
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAdd
 * Description:
 *      Set the Alarm->AlarmCond.Type to something other than 
 *      SAHPI_STATUS_COND_TYPE_USER.
 *      saHpiAlarmAdd() returns SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P72-16:P72-17
 *    
 */
#include <stdio.h>
#include "saf_test.h"

int Test_Domain(SaHpiSessionIdT session_id)
{
	SaHpiAlarmT NewAlarm;
	SaErrorT status;
	int retval = SAF_TEST_UNKNOWN;
	int index;
	SaHpiStatusCondTypeT array[] = {
		SAHPI_STATUS_COND_TYPE_SENSOR,
		SAHPI_STATUS_COND_TYPE_RESOURCE,
		SAHPI_STATUS_COND_TYPE_OEM,
		-1		/* watcher */
	};
	//
	// Create a new Alarm
	//
	NewAlarm.Severity = SAHPI_MINOR;
	NewAlarm.Acknowledged = SAHPI_FALSE;
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

	for (index = 0; array[index] != -1; ++index) {
		NewAlarm.AlarmCond.Type = array[index];
		status = saHpiAlarmAdd(session_id, &NewAlarm);

		if (status != SA_ERR_HPI_INVALID_PARAMS) {
			e_print(saHpiAlarmAdd,
				SA_ERR_HPI_INVALID_PARAMS, status);
			retval = SAF_TEST_FAIL;

			// Clean up
			if (status == SA_OK)
				status =
				    saHpiAlarmDelete(session_id,
						     NewAlarm.AlarmId, 0);
			break;
		} else
			retval = SAF_TEST_PASS;
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

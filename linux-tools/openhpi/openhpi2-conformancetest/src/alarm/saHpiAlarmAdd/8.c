/*      -*- linux-c -*-
 *
 * (C) Copyright University of New Hampshire 2006
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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAdd
 * Description:
 *      Add more user alarms than the DAT can hold.
 *      Expected return: SA_ERR_HPI_OUT_OF_SPACE
 * Line:        P72-18:P72-19
 *    
 */

#include <stdio.h>
#include <string.h>
#include "saf_test.h"

/*********************************************************************
 *
 * Add a user alarm.
 *
 *********************************************************************/

SaErrorT addUserAlarm(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	SaHpiAlarmT NewAlarm;

	NewAlarm.Severity = SAHPI_MINOR;
	NewAlarm.Acknowledged = SAHPI_FALSE;
	NewAlarm.AlarmCond.Type = SAHPI_STATUS_COND_TYPE_USER;
	NewAlarm.AlarmCond.ResourceId = SAHPI_UNSPECIFIED_RESOURCE_ID;
	NewAlarm.AlarmCond.Data.Language = SAHPI_LANG_ENGLISH;
	NewAlarm.AlarmCond.Data.DataType = SAHPI_TL_TYPE_TEXT;
	NewAlarm.AlarmCond.Data.DataLength = 1;
	NewAlarm.AlarmCond.Data.Data[0] = 'a';
	NewAlarm.AlarmCond.Name.Length = 1;
	NewAlarm.AlarmCond.Name.Value[0] = 'T';

	status = saHpiAlarmAdd(sessionId, &NewAlarm);
	if (status != SA_OK) {
		e_print(saHpiAlarmAdd, SA_OK, status);
	}

	return status;
}

/*********************************************************************
 *
 * Add lots of user alarms to the DAT in order to
 * produce an out of space error.
 *
 *********************************************************************/

int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	SaHpiUint32T i;
	int retval = SAF_TEST_UNKNOWN;
	SaHpiDomainInfoT domainInfo;

	status = saHpiDomainInfoGet(sessionId, &domainInfo);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiDomainInfoGet, SA_OK, status);
	} else if (domainInfo.DatUserAlarmLimit == 0) {	// no fixed limit of user alarms
		retval = SAF_TEST_NOTSUPPORT;
	} else {
		retval = SAF_TEST_UNKNOWN;

		// Add one extra to be sure we exceed limit.  It is possible
		// to get an out of space error before we reach the limit.

		for (i = 0; i < domainInfo.DatUserAlarmLimit + 1; i++) {
			status = addUserAlarm(sessionId);
			if (status == SA_ERR_HPI_OUT_OF_SPACE) {
				retval = SAF_TEST_PASS;
				break;
			} else if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
				break;
			}
		}

		if (retval == SAF_TEST_UNKNOWN) {
			retval = SAF_TEST_FAIL;
			m_print("Did not get SA_ERR_HPI_OUT_OF_SPACE error!");
		}
		// Delete all of the user alarms that we added

		status =
		    saHpiAlarmDelete(sessionId, SAHPI_ENTRY_UNSPECIFIED,
				     SAHPI_MINOR);
		if (status != SA_OK) {
			e_print(saHpiAlarmDelete, SA_OK, status);
		}
	}

	return retval;
}

/*********************************************************************
 *
 * Main Program
 *
 *********************************************************************/

int main(int argc, char **argv)
{
	return process_all_domains(NULL, NULL, Test_Domain);
}

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
 *      Donald A. Barre
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmAcknowledge
 * Description:
 *      If the AlarmId is SAHPI_ENTRY_UNSPECIFIED and no alarms
 *      are present that meet the requested Severity, this
 *      function will have no effect.
 *      Expected return: SA_OK.
 * Line:        P71-1:P71-2
 *    
 */

#include <stdio.h>
#include "saf_test.h"

/*************************************************************************
 *      
 * Does the DAT have an alarm with the given severity?
 *
 *************************************************************************/

SaErrorT hasAlarmWithSeverity(SaHpiSessionIdT sessionId,
			      SaHpiSeverityT severity, SaHpiBoolT * found)
{
	SaErrorT status;
	SaHpiAlarmT alarm;

	*found = SAHPI_FALSE;
	alarm.AlarmId = SAHPI_FIRST_ENTRY;
	status = saHpiAlarmGetNext(sessionId, severity, SAHPI_FALSE, &alarm);
	if (status == SA_ERR_HPI_NOT_PRESENT) {
		*found = SAHPI_FALSE;
		status = SA_OK;
	} else if (status == SA_OK) {
		*found = SAHPI_TRUE;
	} else {
		e_print(saHpiAlarmGet, SA_OK | SA_ERR_HPI_NOT_PRESENT, status);
	}
	return status;
}

/*************************************************************************
 *      
 * Acknowledge all alarms of a given severity.
 *
 *************************************************************************/

int run_test(SaHpiSessionIdT sessionId, SaHpiSeverityT severity)
{
	SaErrorT status;
	int retval;

	status =
	    saHpiAlarmAcknowledge(sessionId, SAHPI_ENTRY_UNSPECIFIED, severity);
	if (status == SA_OK) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiAlarmAcknowledge, SA_OK, status);
	}
	return retval;
}

/*************************************************************************
 *      
 * Try to find a severity that isn't used in the DAT and then
 * acknowledge alarms with that severity.
 *
 *************************************************************************/

int Test_Domain(SaHpiSessionIdT sessionId)
{
	SaErrorT status;
	int retval;
	SaHpiBoolT found;

	status = hasAlarmWithSeverity(sessionId, SAHPI_MINOR, &found);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
	} else if (!found) {
		retval = run_test(sessionId, SAHPI_MINOR);
	} else {
		status = hasAlarmWithSeverity(sessionId, SAHPI_MAJOR, &found);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
		} else if (!found) {
			retval = run_test(sessionId, SAHPI_MAJOR);
		} else {
			status =
			    hasAlarmWithSeverity(sessionId, SAHPI_CRITICAL,
						 &found);
			if (status != SA_OK) {
				retval = SAF_TEST_UNRESOLVED;
			} else if (!found) {
				retval = run_test(sessionId, SAHPI_CRITICAL);
			} else {
				retval = SAF_TEST_NOTSUPPORT;
				m_print("Could not find an Severity (minor, major, or critical) "
						"that isn't being used by any of the alarms in the DAT.");
			}
		}
	}

	return retval;
}

/*************************************************************************
 *      
 * Main Program.
 *
 *************************************************************************/

int main(int argc, char **argv)
{
	int retval = SAF_TEST_UNKNOWN;

	retval = process_all_domains(NULL, NULL, Test_Domain);

	return (retval);
}

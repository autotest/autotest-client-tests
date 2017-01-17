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
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiAlarmDelete
 * Description:
 *      If a non-user alarm is present, attempt to delete it.
 *      saHpiAlarmDelete() returns SA_ERR_HPI_READ_ONLY.
 * Line:        P73-22:P73-22
 *    
 */

#include <stdio.h>
#include "saf_test.h"

#define HPI_TEST_RETRY_MAX  30    // re-try 30 times

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
 * Test deleting user alarms of ALL severities and verify that
 * system alarms were not deleted.
 *
 ************************************************************************/

int Test_Domain(SaHpiSessionIdT sessionId)
{
    SaHpiAlarmT systemAlarm;
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
        status = saHpiAlarmDelete(sessionId, systemAlarm.AlarmId, 0);
        if (status == SA_ERR_HPI_READ_ONLY) {
            retval = SAF_TEST_PASS;
        } else {
            retval = SAF_TEST_FAIL;
            e_print(saHpiAlarmDelete, SA_ERR_HPI_READ_ONLY, status);
        }
    }

    return retval;
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


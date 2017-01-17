/*      -*- linux-c -*-
 *
 * Copyright (c) 2003 by Intel Corp.
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
 *     Kevin Gao <kevin.gao@intel.com>
 *     Carl McAdams <carlmc@us.ibm.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiWatchdogTimerReset
 * Description:
 *      Initialize and restart each watchdog timer.
 *      Expected return: SA_OK.
 * Line:        P119-18:P119-18
 *    
 */

#include <stdio.h>
#include <string.h>
#include "../include/watchdog_test.h"

/*************************************************************************
 *
 * Reset a watchdog timer.
 *
 *************************************************************************/

int processWatchdogRdr(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiRdrT * rdr, SaHpiWatchdogRecT * watchdogRec)
{
	SaErrorT status;
	int retval;
	SaHpiWatchdogT watchdog;
	SaHpiWatchdogT old_watchdog;
	SaHpiWatchdogNumT wd_num = watchdogRec->WatchdogNum;

	// Save the original watchdog timer for later restoration.

	status =
	    saHpiWatchdogTimerGet(sessionId, resourceId, wd_num, &old_watchdog);
	if (status != SA_OK) {
		retval = SAF_TEST_UNRESOLVED;
		e_print(saHpiWatchdogTimerGet, SA_OK, status);
	} else {

		initSmsWatchdogFields(&watchdog);

		status =
		    saHpiWatchdogTimerSet(sessionId, resourceId, wd_num,
					  &watchdog);
		if (status != SA_OK) {
			retval = SAF_TEST_UNRESOLVED;
			e_print(saHpiWatchdogTimerSet, SA_OK, status);
		} else {
			status =
			    saHpiWatchdogTimerReset(sessionId, resourceId,
						    wd_num);
			if (status == SA_OK) {
				retval = SAF_TEST_PASS;
			} else {
				retval = SAF_TEST_FAIL;
				e_print(saHpiWatchdogTimerReset, SA_OK, status);
			}

			// Restore the original watchdog timer.

			status =
			    saHpiWatchdogTimerSet(sessionId, resourceId, wd_num,
						  &old_watchdog);
			if (status != SA_OK) {
				e_print(saHpiWatchdogTimerSet, SA_OK, status);
			}
		}
	}

	return retval;
}

/*************************************************************************
 *
 *  Process all Watchdog RDRs.  The below macro expands to
 *  generate all of the generic code necessary to call the given
 *  function to process an RDR.
 *
 *************************************************************************/

processAllWatchdogRdrs(processWatchdogRdr)

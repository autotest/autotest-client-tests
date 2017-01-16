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
 *     Qun Li <qun.li@intel.com>
 *     Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiWatchdogTimerGet
 * Description:
 *      Call on a resource which supports Watchdog timers.
 *      Expected return: SA_OK.
 * Line:        P116-20:P116-20
 *
 */

#include <stdio.h>
#include "../include/watchdog_test.h"

/*************************************************************************
 *
 * Verify that the watchdog is valid.
 *
 *************************************************************************/

static __inline__ int __check_data_boundary(const SaHpiWatchdogT * wd)
{
	return isValidWatchdogTimerUse(wd->TimerUse) &&
	    isValidWatchdogAction(wd->TimerAction) &&
	    isValidWatchdogPretimerInterrupt(wd->PretimerInterrupt);
}

/*************************************************************************
 *
 * Get a watchdog timer.
 *
 *************************************************************************/

int processWatchdogRdr(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiRdrT * rdr, SaHpiWatchdogRecT * watchdogRec)
{
	SaErrorT status;
	int retval;
	SaHpiWatchdogT watchdog;
	SaHpiWatchdogNumT wd_num = watchdogRec->WatchdogNum;

	status = saHpiWatchdogTimerGet(sessionId, resourceId,
				       wd_num, &watchdog);

	if (status != SA_OK) {
		retval = SAF_TEST_FAIL;
		e_print(saHpiWatchdogTimerGet, SA_OK, status);
	} else if (__check_data_boundary(&watchdog)) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		m_print("Watchdog is invalid!");
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

/*      -*- linux-c -*-
 *
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
 *      Carl McAdams <carlmc@us.ibm.com>
 *      Donald A. Barre <dbarre@unh.edu>
 *
 * Spec:        HPI-B.01.01
 * Function:    saHpiWatchdogTimerSet
 * Description:
 *      Call saHpiWatchdogTimerSet passing in an out-of-range
 *      value for the TimerAction Field.
 *      Expected return: SA_ERR_HPI_INVALID_PARAMS.
 * Line:        P117-30:P117-30
 *    
 */

#include <stdio.h>
#include "../include/watchdog_test.h"

/*************************************************************************
 *
 * Test an invalid TimerAction value.
 *
 *************************************************************************/

int processWatchdogRdr(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiRdrT * rdr, SaHpiWatchdogRecT * watchdogRec)
{
	SaErrorT status;
	int retval;
	SaHpiWatchdogT Watchdog;
	SaHpiWatchdogNumT w_num = watchdogRec->WatchdogNum;

	initWatchdogFields(&Watchdog);
	Watchdog.TimerAction = SAHPI_WA_POWER_CYCLE + 1;	//out of range

	//  Call saHpiWatchdogTimerSet passing in an 
	//  out-of-range value for the TimerAction Field.

	status = saHpiWatchdogTimerSet(sessionId, resourceId, w_num, &Watchdog);

	if (status == SA_ERR_HPI_INVALID_PARAMS) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiWatchdogTimerSet, SA_ERR_HPI_INVALID_PARAMS,
			status);
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

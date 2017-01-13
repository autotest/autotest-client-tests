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
 *      Call saHpiWatchdogTimerSet passing in a PreTimeoutInterval
 *      which is greater than the initial count.
 *      Expected return: SA_ERR_HPI_INVALID_DATA.
 * Line:        P117-36:P117-36
 *    
 */

#include <stdio.h>
#include "../include/watchdog_test.h"

/*************************************************************************
 *
 * Pass in a PreTimeoutInterval that is greater than the InitialCount.
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
	Watchdog.InitialCount = 100;
	Watchdog.PreTimeoutInterval = 500;

	//  Call saHpiWatchdogTimerSet passing in a PreTimeoutInterval
	//  which is greater than the initial count.

	status = saHpiWatchdogTimerSet(sessionId, resourceId, w_num, &Watchdog);

	if (status == SA_ERR_HPI_INVALID_DATA) {
		retval = SAF_TEST_PASS;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiWatchdogTimerSet, SA_ERR_HPI_INVALID_DATA, status);
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

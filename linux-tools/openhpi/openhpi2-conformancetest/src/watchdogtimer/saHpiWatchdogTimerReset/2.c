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
 * Function:    saHpiWatchdogTimerReset
 * Description:
 *      Call saHpiWatchdogTimerReset passing in a bad SessionId.
 *      Expected return: SA_ERR_HPI_INVALID_SESSION.
 * Line:        P29-47:P29-49
 *    
 */

#include <stdio.h>
#include "../include/watchdog_test.h"

/*************************************************************************
 *
 * Test an invalid session id.
 *
 *************************************************************************/

int processWatchdogRdr(SaHpiSessionIdT sessionId,
		       SaHpiResourceIdT resourceId,
		       SaHpiRdrT * rdr, SaHpiWatchdogRecT * watchdogRec)
{
	SaErrorT status;
	int retval;
	SaHpiSessionIdT bad_session_id = BAD_SESSION_ID;
	SaHpiWatchdogNumT w_num = watchdogRec->WatchdogNum;

	// rule out the 1::4000000000 chance that this is a valid id

	if (bad_session_id == sessionId) {
		bad_session_id++;
	}
	//  Call saHpiWatchdogTimerReset passing with a bad SessionId

	status = saHpiWatchdogTimerReset(bad_session_id, resourceId, w_num);
	if (status == SA_ERR_HPI_INVALID_SESSION) {
		retval = SAF_TEST_PASS_AND_EXIT;
	} else {
		retval = SAF_TEST_FAIL;
		e_print(saHpiWatchdogTimerReset, SA_ERR_HPI_INVALID_SESSION,
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
